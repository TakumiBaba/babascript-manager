API = "http://localhost:3000/api"

class Application extends Backbone.Router

  routes:
    'group/new': 'createGroup'
    'groups/:name(/:type)': 'group'
    'login': 'login'
    '': 'me'
    'user/:name': 'user'

  status: ""
  api: "http://localhost:3000/api"
  linda: null

  initialize: ->
    $.ajax
      url: "#{@api}/islogin"
    .done (data) =>
      console.log "app initialize done"
      @user = new User()
      @groups = new Groups()
      @linda = new Linda().connect io.connect "http://localhost:3000"
      @sidebar = new Sidebar @user
      @mainView = new MainView @user
      @linda.io.once "connect", =>
        Backbone.history.start
          pushState: true
        if data.status is true
          id = data.session.user.id
          @user.id = id
          @groups.url = "/api/user/#{id}/group"
          @user.fetch()
          @groups.fetch()
        else
          @navigate "/login", yes
        
      $(document).delegate "a", "click", (event)->
        event.preventDefault()
        href = $(@).attr "href"
        if href
          App.navigate href, yes

  hoge: ->
    console.log "hogefuga"

  me: ->
    console.log "user view"
    @mainView.userView.render()

  user: ->
    console.log "user"

  createGroup: ->

  group: (name, type)->
    @mainView.group name

  login: ->
    @mainView.login()
    console.log "login"

class Sidebar extends Backbone.View
  el: "#sidebar"

  initialize: (@user)->
    @listenTo @user, "change", @change
    @groupList = $(".group-list")
    @groupCreateModal = new GroupCreateModalView()

  appendGroupToList: (model)->
    group = new GroupElement model
    @groupList.append group.el

  change: (model)->
    $(@.el).find("h3").html model.get("id")
    @groupList.empty()
    for g in model.get "groups"
      @appendGroupToList g

class HeaderView extends Backbone.View
  el: "#header-view"

  initialize: (@user)->
    @listenTo @user, "change", @change
    @groupList = $(".groups")
    @groupCreateModal = new GroupCreateModalView()
    console.log @groupCreateModal

  append: (user)->
    console.log user

  appendGroupToList: (model)->
    # element = $("#group-element")
    # template = _.template(element.html())({name: model.name})
    console.log model
    group = new GroupElement model
    console.log group
    @groupList.append group.el

  change: (user)->
    @groupList.empty()
    for g in user.get "groups"
      @appendGroupToList g

class GroupElement extends Backbone.View

  initialize: (@model)->
    @el = _.template($("#group-element").html())({name: @model.name})
    @delegateEvents
      "click a": "navigate"

  navigate: (e)->
    console.log "navigate!"
    App.navigate "/groups/#{@name}", true
    e.preventDefault()

class MainView extends Backbone.View
  el: "#main-view"

  initialize: (@user)->
    @groupViews = {}
    @userView  = new UserView()
    @listenTo App.groups, "add", @createGroupView
    @listenTo App.groups, "remove", @removeGroupView
      
  createGroupView: (model)=>
    view = new GroupView(model)
    name = model.get "name"
    @groupViews[name] = view
    console.log @groupViews

  removeGroupView: (model)->
    name = model.get "name"
    @groupView[name] = null

  group: (name)->
    if !@groupViews[name]?
      App.navigate "/", yes
      return
    $(@.el).empty
    $(@.el).html @groupViews[name].el

  user: ->
    @userView.render()

  login: ->
    $(@.el).empty()
    loginView = new LoginView()
    loginView.render()

class LoginView extends Backbone.View

  events:
    "click .login-button": "login"

  render: ->
    html = _.template($("#login-view").html())()
    $(@.el).append html
    $("body").append @.el
    $("#login-modal").modal()

  login: (e)->
    e.preventDefault()
    id = $(@.el).find(".form-id").val()
    pass = $(@.el).find(".form-pass").val()
    console.log id, pass
    $.ajax
      url: "#{App.api}/login"
      type: "POST"
      data:
        id: id
        pass: pass
      dataType: "json"
    .done (data)=>
      if data.status is true
        id = data.user.id
        App.user.id = id
        App.groups.url = "/api//users/#{id}/group"
        App.user.fetch()
        App.groups.fetch()
        App.navigate "/", true
        $("#login-modal").modal('hide')
      else
        window.alert "IDかパスワードが間違ってます"


  signup: (e)->
    e.preventDefault()
    id = $(@.el).find(".login-id").val()
    pass = $(@.el).find(".login-pass").val()
    $.ajax
      url: "#{App.api}/signup"
      type: "POST"
      data:
        id: id
        pass: pass
      dataType: "json"
    .done (data)=>
      if data.status is true
        window.alert "サインアップ完了！"
        App.navigate "/", true
      else
        window.alert "既に利用されています。他のIDをご利用ください。"

class UserView extends Backbone.View
  tagName: "div"

  initialize: ->
    @listenTo App.user, "change", @change

  change: (model)->
    $(@.el).html _.template($("#user-view").html())
    App.taskTupleSpace = App.linda.tuplespace("active_task")
    App.taskTupleSpace.watch {group: App.user.get("id")}, (err, tuple)=>
      d = tuple.data
      v = ""
      p = new GroupTask tuple
      # if d.status is "eval"
      #   v = "タスク「#{d.key}」が配信待ちです"
      # else if d.status is "receive"
      #   v = "#{d.id}さんが、タスク「#{d.key}」を実行中です"
      # else if d.status is "return"
      #   v = "#{d.id}さんが、タスク「#{d.key}」を終了しました。"
      #   v += "返り値は「#{d.value}」です"
      # p = $("<p></p>").html v
      $(@.el).find(".task-list").prepend p.el

  render: ->
    $("#main-view").html @.el

  show: ->
    $(@.el).show()

  hide: ->
    $(@.el).hide()

class GroupView extends Backbone.View
  tagName: "div"

  events:
    "click button.add-member": "addMember"
    "submit input.form-control": "addMember"
    "click button.remove-member": "removeMember"

  initialize: (@model)->
    name = @model.get "name"
    @render()

    @members = new GroupMembers name
    @listenTo @members, "reset",  @reset
    @listenTo @members, "add",    @add
    @listenTo @members, "remove", @remove
    @members.fetch()
    @trs = []
    @groupTasks = {}

    # @programs = new Programs name
    # @listenTo @programs, "add",    @program.add
    # @listenTo @programs, "remove", @program.remove
    # @programs.fetch()

    @activeTask = App.linda.tuplespace("active_task")
    @activeTask.watch {group: name}, @checkActiveTask

    @activeUser = App.linda.tuplespace("active_user")

  program:
    add: (model)->
      console.log "program add"
      console.log model

    remove: (model)->
      console.log model

  checkActiveTask: (err, tuple)=>
    console.log "check active task!!"
    data = tuple.data
    v = ""
    console.log tuple
    p = new GroupTask tuple
    task = @groupTasks[tuple.data.cid]
    if !task?
      task = {}
    task[data.status] = p
    # if data.status is "return"
    #   console.log task["eval"]
    #   clearIntervalId = task["eval"].intervalId
    #   console.log "clearIntervalId is #{clearIntervalId}"
    $(@.el).find(".task-list").prepend p.el

  change: (model)->
    console.log "group model change"
    console.log model
    @render()

  render: ->
    $(@.el).append _.template($("#group-view-member").html())()
    $(@.el).append _.template($("#group-view-analytics").html())()
    # $(@.el).append _.template($("#group-view-program").html())()

  # collection
  reset: (collection)->
    console.log "reset"
    console.log collection

  add: (model)->
    tr = new GroupMemberTr model
    @trs.push tr
    $(@.el).find("tbody.member-list").append tr.el
    # @activeUser.read {id: model.get("sid")}, (err, tuple)->
    @activeUser.watch {id: model.get("sid")}, (err, tuple)-> #arguments.callee
      for key, value of App.mainView.groupViews
        for tr in value.trs
          if tr.getId() is tuple.data.id
            id = tuple.data.id
            status = "unknown"
            if tuple.data.status is "web"
              status = "ok"
            $(".#{id}_status").html status
            # tr.setStatus tuple.data.status
    # console.log 'add'
    # console.log model
    # html = _.template($("#group-view-member-element").html())
    #   id: model.get "id"
    # $(@.el).find("tbody.member-list").append html

  remove: (model)->
    tr = _.find @trs, (tr)->
      return tr.getId() is model.get("id")
    # tbody = $(@.el).find("tbody.member-list")
    # tbody.children().each ->
    #   u = $(@).find('th.member-id').html()
    #   a = model.get("id")
    #   if $(@).find('th.member-id').html() is model.get("id")
    #     $(@).remove

  changeMember: (model)->
    console.log "change member"
    template = _.template($("#group-view-member-element").html())
      member: model
    console.log $(@.el).find("tbody")
    $(@.el).find(".member-list").append template
    console.log template

  addMember: (e)->
    e.preventDefault()
    console.log "member"
    id = $(@.el).find(".new-member-name").val()
    if id.length > 0
      user = new User
        id: id
        isNew: true
      @members.push user
      @members.save()
      $(@.el).find(".new-member-name").val("")


  removeMember: (e)->
    e.preventDefault()
    id = $(e.currentTarget).parent().next().html()
    @members.each (u)=>
      if u.id is id
        @members.remove u
        $(e.currentTarget).parent().parent().remove()
    @members.save()

class GroupTask extends Backbone.View
  tagName: "p"

  initialize: (tuple)->
    data = tuple.data
    v = ""
    @now = moment().format()
    @type = data.status
    @color = ""
    if data.status is "eval"
      v = "タスク「#{data.key}」が配信待ちです"
      @color = "black"
      @time = moment().format()
    else if data.status is "receive"
      v = "#{data.id}が、タスク「#{data.key}」を実行中です"
      @color = "red"
    else if data.status is "return"
      v = "#{data.id}が、タスク「#{data.key}」を終了しました。"
      v += "返り値は「#{data.value}」です"
      @color = "green"
    $(@el).html v
    $(@el).css
      color: @color


class GroupMemberTr extends Backbone.View

  initialize: (@model)->
    @render()

  render: ->
    @el = _.template($("#group-view-member-element").html())
      id: @model.get "id"

  getId: ->
    return @model.get 'id'

  setStatus: (status)->
    # console.log status
    # console.log $(@.el).find("th.status")
    # console.log $(@.el).find("th.status")[0]
    # console.log $(@.el).find("th.status")[0].innerHTML = "hoge"
    console.log $(@el)
    $($(@.el).find("th.status")[0]).html status

  setTask: (task)->
    console.log task
    $(@.el).find("th.task").html task

  remove: ->
    $(@.el).remove()


class GroupCreateModalView extends Backbone.View
  el: "#group-create"

  events:
    "click .create-group": "create"

  initialize: ->
    console.log 'group create'

  create: ->
    name = $(@.el).find(".group-name").val()
    if name.length > 0
      group = new GroupModel
        name: name
        users: [App.user.get "_id"]
      group.save
        success: ->
          App.groups.push group
      $(@.el).modal('toggle')

class User extends Backbone.Model
  urlRoot: "#{API}/user"

  default:
    login: false

class Users extends Backbone.Collection
  model: User
  # sync: ->
  #   console.log arguments

class GroupModel extends Backbone.Model
  urlRoot: "#{API}/group/"

  parse: (res)->
    @members = new GroupMembers()
    _.each res.users, (u)=>
      @members.add new User(u)
    return res

class Groups extends Backbone.Collection
  model: GroupModel

  parse: (res)->
    console.log res
    return res

class GroupMembers extends Backbone.Collection
  model: User

  initialize: (@name)->
    @url = "#{API}/group/#{@name}/member"

  save: (options)->
    Backbone.sync "update", @, options

class ProgramModel extends Backbone.Model
  urlRoot: "#{API}/program/"

  default:
    name: "test"
    program: "function(){\nhogefuga\n}"

class Programs extends Backbone.Collection
  model: ProgramModel

  initialize: (@name)->
    @url = "#{API}/group/#{@name}/programs"

class DeviceModel extends Backbone.Model
  urlRoot: "#{API}/device/"

# class Sidebar extends Backbone.View
#   el: ".sidebar"
#   events:
#     "click a": "focus"

#   initialize: (@user)->
#     console.log @user
#     @listenTo @user, "change", @change
#     @groupsView = $(".group-list")

#   focus: (name)->
#     console.log "focus!"
#     console.log @

#   append: (model)->
#     template = _.template $("#sidebar-group-element").html()
#     @groupsView.append template({name: model.name, description: ""})

#   change: (models)->
#     console.log "change!!"
#     @groupsView.empty()
#     console.log models
#     for model in models.get("groups")
#       @append model

#   changeFocus: (target)->
#     $(@.el).find("li").each ->
#       if $(@.el).hasClass target
#         $(@.el).addClass "active"
#       else
#         $(@.el).removeClass "active"

# class MainView extends Backbone.View
#   el: "#main-view"

#   initialize: ->


#   reset: ->
#     $(@.el).empty()

#   setGroupView: (name)->
#     @reset()
#     @group = new Group name
#     groupView = new GroupView()
#     groupView.render()

#   setUserView: ->
#     @reset()

#     userView = new UserView()
#     userView.render()

# class ContentView extends Backbone.View
#   el: "#content-view"

#   intialize: ->


#   change: (model)->
#     $(@.el).empty()

# class UserView extends Backbone.View

#   initialize: (@user)->


#   render: ->
#     template = _.template $("#user-view").html()
#     $("#main-view").html template()

# class GroupView extends Backbone.View

#   initialize: (name)->
#     group = new Group(name)
#     @memberListView = new MemberListView group

#   render: ->
#     console.log "render"
#     template = _.template $("#group-view").html()
#     $("#main-view").html template()

  # getMemberListView: ->
  #   $(@memberListView.el).show()
  #   return @memberListView

# class MemberListView extends Backbone.View

#   initialize: (@group)->
#     @listenTo @group, "change", @change

#   change: (model)->
#     console.log model

$ =>
  window.App = new Application()
  # socket = io.connect "http://localhost:3000"
  # linda = (new Linda()).connect socket
  # linda.io.once "connect", ->
  #   console.log "connect!!"
  #   ts = linda.tuplespace "active_task"
  #   ts.watch {group: "masuilab"}, (err, tuple)->
  #     d = tuple.data
  #     console.log d
  #     if d.status is "eval"
  #       console.log "タスク「#{d.key}」が配信待ちです"
  #     else if d.status is "receive"
  #       console.log "#{d.id}さんが、タスク「#{d.key}」を実行中です"
  #     else if d.status is "return
  #       console.log "#{d.id}さんが、タスク「#{d.key}」を終了しました"