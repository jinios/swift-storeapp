# 스토어 앱
## 완성화면
<img src="./screenshot/step8.gif" width="35%">

### 주요 기능
- 네트워크 환경에서 주문하기 기능을 구현한 애플리케이션
- Slack Web Hook으로 주문하기 기능 수행
- 네트워크 연결성 확인: StatusBar 변경으로 연결성 구분
  - `wifi: 파란색` / `WWAN: 하늘색` / `네트워크 유실: 빨간색`

### Step1 ~ Step7 완성화면
[링크 - 단계별 완성화면](https://github.com/jinios/swift-storeapp/blob/jinios/Readme2.md)

## 사용한 기술
- Network 병렬처리, Caching, UITableView, UIScrollView, AutoLayout, Web Hook(slack) 등


## 사용한 라이브러리
- [Toaster](github.com/devxoul/Toaster) : 상품 클릭시 화면하단에 Toast기능 실행(안드로이드 Toast메시지 스타일)
- [Alamofire](https://github.com/Alamofire/Alamofire) : Network Reachability status 확인을 위해 사용

## 공부한 부분
### 데드락(Deadlock)
- 문제 코드   
```swift
// TableViewCell.swift

  private func setItemImage(imageURL: String) {
    // 1. ImageSetter의 download()호출
    ImageSetter.download(with: imageURL, handler: { imageData in
      // 3. download()함수가 종료되면서 핸들러가실행됨. 같은 main queue라서 문제발생  
      DispatchQueue.main.sync { [weak self] in
        guard let data = imageData else { return }
        self?.itemImage.image = UIImage(data: data)
      }
    })
  }
```

```swift
// TableViewCell에서 ImageSetter의 download가 호출

class func download(with url: String, handler: @escaping((Data) -> Void)) {
    let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let imageSavingPath = cacheURL.appendingPathComponent(URL(string: url)!.lastPathComponent)

    // 2. 아래 줄 코드의 existFile이 체크되고 handler가 실행됨
    if let imageData = existFile(at: imageSavingPath) {
        handler(imageData)
    } else {
        URLSession.shared.downloadTask(with: URL(string: url)!) { (tmpLocation, response, error) in
          // do something...
        }.resume()
    }
}
```

- 컴플리션 핸들러를 처리하는 코드에서 데드락 상황 발견
  - main queue에서 또 main.sync로 돌아가는 코드블럭을 호출
  - setItemImage() 함수는 ImageSetter의 download()를 호출하며, 인자로 url과 함께 컴플리션 핸들러를 넘긴다. (main queue에서 실행)
  - 해당 컴플리션 핸들러의 코드 블럭을 편의상 `A블럭`이라고 칭한다.
  - 이때 `A블럭`의 관련 worker는 다음과 같다.
    - `Assignor : setItemImage()`, `Assignee : download()`
  - download()는 함수를 빠져나오는 시점에 `A블럭`을 실행한다.
  - 이때의 `A블럭`의 worker는
    - `Assignor : download()`, `Assignee : setItemImage()`
  - 두 worker가 모두 main queue에서 sync로 동작하기때문에, 서로가 교차하여 서로를 가리키고있고 서로 일이 끝나기만을 기다리는 데드락 상황이 발생.
  - **handler의 코드를 async로 변경하여 문제를 해결할 수 있다.**

### 테이블뷰 업데이트 시 데이터 동기화
- 테이블뷰에 표시될 데이터를 네트워크에서 다운로드할때 데이터를 섹션 단위로 받아올때, 전체 UI를 업데이트(`tableView.reloadData()`)하는 것이아니라 데이터가 변경된 row들만 변경되도록(`tableView.insertRows()`) 처리하려했지만 UI업데이트 도중 데이터 변경(비동기적으로 다운로드 진행중)으로 인해 TableView에서 크래시 발생하는 문제.
```swift
private func resetTableView(indexPaths: [IndexPath]) {
    DispatchQueue.main.sync { [weak self] in // async는 크래시발생
        self?.tableView.beginUpdates()
        self?.tableView.insertRows(at: indexPaths, with: .automatic)
        self?.tableView.endUpdates()
    }
}
```
- `beginUpdates()`와 `endUpdates()`사이의 시점에서는 모델이 변경되면 안됨
- 테이블뷰 데이터소스는 reload나 insert를 할때 변경이 필요한 부분(테이블 뷰 내의 특정 섹션이나 셀)을 담당하는 모델이 같은 수인지 내부적으로 확인하는 과정을 거친다.
  - 이는 변경동작이 필요없는 곳에는 동작을 하지 않고 낭비를 막으려고 이렇게 동작함.
- 위의 코드에서 `async`로 동작하도록 구현하면 크래시 발생
- `insertSection/insertRows`, 혹은 `reloadSection/rows`로 인해서 변경된 테이블뷰의 데이터 수가 변경 전과 다르다는 에러.
 ```
  Terminating app due to uncaught exception 'NSInternalInconsistencyException',
  reason: 'Invalid update: invalid number of sections.  
  The number of sections contained in the table view after the update (0) must be equal to the number of sections contained in the table view before the update (2), plus or minus the number of sections inserted or deleted (0 inserted, 0 deleted).
  ```
- [에러자료 링크 1- Error 'Invalid update: invalid number of rows in section 0' attempting to delete row in table](https://stackoverflow.com/questions/30516970/error-invalid-update-invalid-number-of-rows-in-section-0-attempting-to-delete)
- [에러자료 링크 2 - Insert rows to UITableView crash](https://stackoverflow.com/questions/13965591/insert-rows-to-uitableview-crash)
### 원인 분석 상세 & 해결
- 확인해보니 insertRows에 전달되는 IndexPath는 모두 잘 만들어져 전달되었다.
- **하지만 update를 시작하고 insert하고 update가 끝나는 동작이 async로 작동하여 모델 변경이 언제 되는지 모르는 문제가 있었다.**
- URLSession으로 모델 업데이트(async) - 0개의 데이터로 테이블뷰 그림 **- 모델 업데이트(async) noti로 테이블뷰 업데이트 시작 - 다른 모델도 업데이트 되는 중**
- 해당 동작을 async하게 동작하면, URLSession에서 모델을 받아오는게 전부 완료되지 않고 다른 스레드에서 다른 섹션을 담당하는 모델이 업데이트되고있는 상태에서 다른 섹션의 업데이트를 비동기적으로 요청하고, 테이블뷰를 비동기적으로 업데이트하려고하니까 업데이트 전후의 데이터 수가 일치하지 않는 문제가 발생한다.
  - 쉽게말해, 1섹션의 테이블뷰를 업데이트하고있는데 2의 데이터가 만들어져서 또 2 섹션을 업데이트하라고 noti가 오는 상황
- `beginUpdates()`와 `endUpdates()`사이에서 모델과 테이블뷰가 가진 데이터의 수가 같아야하는게 포인트! (업데이트 전의 데이터가 0개이면 테이블뷰의 rows도 0, 데이터가 변경되서 3개가 되면 rows도 3개여야하며, 에러메시지에서도 언급하고 있는 내용이다.)
- 따라서 모델은 비동기로 업데이트된다고 하더라도, 테이블뷰 업데이트는 sync하게 동작하도록 하여 메인스레드에서 직렬적으로(차례대로) 업데이트되게하여 모델업데이트와 테이블뷰 업데이트의 타이밍을 맞춘다!

### downloadTask() 동작방식
- `func downloadTask(with url: URL,
completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask`
- downloadTask가 일반 dataTask랑은 다르게 컴플리션 핸들러에서 data가 아닌 location(URL-첫번째파라미터)을 받는데, 어떻게 다운로드가 동작하는지?
- 컴플리션핸들러를 거치면서 파일은 location에 저장된거고 location(URL)이 넘어옴. 해당 위치에는 이미 url로부터 다운받아진 이미지파일이 존재함.
- 임시경로에는 `/Users/jeonmijin/Library/Developer/CoreSimulator/Devices/DE1DE4FA-2208-4062-8C55-0673E3019F6C/data/Containers/Data/Application/34D0E5CC-B577-49E2-913A-82DDBA91CB59/tmp/CFNetworkDownload_nEtNzv.tmp` 이런식으로 임시 파일이 저장됨

```swift
// 임시 파일 location으로 바로 이미지 가져와봄
func test() {
       let url = URL(string: "https://cdn.bmf.kr/_data/product/HCCFE/757878b14ee5a8d5af905c154fc38f01.jpg")!

       URLSession.shared.downloadTask(with: url) { (location, response, error) in
           if let error = error {
               print("\(error)")
           }
           if let location = location { // 파일이 저장된 url애 접근하여 UIImage생성
               let img = UIImage(contentsOfFile: location.path)
               DispatchQueue.main.sync {
                   self.view.addSubview(UIImageView(image: img))
               }
           }
       }.resume()
   }
```

### 캐시폴더로 파일 옮기기
1. downloadTask의 컴플리션핸들러에서 받은 location은 tmpLocation
2. tmp경로에서 cache path(imageSavingPath)로 move시
3. imageSavingPath에 같은 이름이 있으면 moveError발생


#### 해당 경로에 파일이 존재하는지 확인 후 Data생성
```swift
  do {
        try fileManager.moveItem(at: tmpLocation, to: imageSavingPath)
            let imageData = try? Data(contentsOf: imageSavingPath)
            handler(imageData)
    } catch {
        if FileManager().fileExists(atPath: imageSavingPath.path) {
            let imageData = try? Data(contentsOf: imageSavingPath)
            handler(imageData)
        } else { print("MOVE Error!") }
```
