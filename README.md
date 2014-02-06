# babascript manager

人力リソース管理用のサービス

socket.ioで通信させる？

常に linda.babascript.org を監視し続けて、書き込まれたタプルを保存し続ける

## models

User
- uuid:String
- name:String
- deviceType:String
- notificationId:String

Group
- id:String
- name:String
- users:Array[User]

Data
- Mix


## Routing

全て json を返す
### グループ系API
- GET    /group/:name
- POST   /group/new
- UPDATE /group/:name
- DELETE /group/:name

### ユーザ系API
- GET    /user/:name
- POST   /user/new
- UPDATE /user/:name
- DELETE /user/:name

### データ系API
- GET /data/group/:name/
- GET /data/user/:name/

### 通知系API
- POST /notification/:userid