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

  initialize: ->
    $.ajax
      url: "#{@api}/islogin"
    .done (data) =>
      console.log "app initialize done"
      @user = new User()
      @headerView = new HeaderView @user
      @mainView = new MainView @user
      @linda = new Linda().connect io.connect "http://localhost:3000"
      @linda.io.once "connect", =>
        console.log "connect"
        Backbone.history.start
          pushState: true
      # @user.id = data.session.user.id
      console.log "ie-i"
      @user.id = "baba"
      @user.fetch()
      # socket = io.connect "http://localhost:3000"
      # @linda = (new Linda()).connect socket
      # App.taskChecker = @linda.tuplespace "active_task"
      console.log "app initialize"
      console.log App.taskChecker
      # if data.status is true
        # @user.id = data.session.user.id
        # @user.fetch()
      # else
      #   @navigate "/login", yes
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
    console.log "group view!!"
    console.log name, type
    @mainView.group name

  login: ->
    @mainView.login()
    console.log "login"

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
    @groupView = new GroupView()
    @userView  = new UserView()
      
  group: (name)->
    console.log name
    if @groupView.name is name
      @groupView.render()
    else
      console.log name
      @groupView.setName name
      @groupView.members.fetch()
      @groupView.programs.fetch()

  user: ->
    @userView.render()

  login: ->
    $(@.el).empty()
    loginView = new LoginView()
    loginView.render()

class LoginView extends Backbone.View
  tagName: "div"
  className: "col-md-6 col-md-offset-3"

  events:
    "click button.login": "login"
    "click button.signup": "signup"
    
  initialize: ->

  login: (e)->
    e.preventDefault()
    id = $(@.el).find(".login-id").val()
    pass = $(@.el).find(".login-pass").val()
    $.ajax
      url: "#{App.api}/login"
      type: "POST"
      data:
        id: id
        pass: pass
      dataType: "json"
    .done (data)=>
      if data.status is true
        App.user.id = data.user.id
        App.user.fetch()
        App.navigate "/", true
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

  render: ->
    $(@.el).html _.template($("#login-view").html())()
    $("#main-view").html @.el

class UserView extends Backbone.View
  tagName: "div"

  initialize: ->
    @listenTo App.user, "change", @change

  change: (model)->
    $(@.el).html _.template($("#user-view").html())

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

  initialize: ->
    # console.log "group view init"
    # @model = new GroupModel()
    # @listenTo @model, "change", @change

    # console.log @model
    @name = ""
    @members = new GroupMembers()
    @listenTo @members, "reset",  @reset
    @listenTo @members, "add",    @add
    @listenTo @members, "remove", @remove

    @programs = new Programs()
    # @listenTo @programs, "reset",  @reset
    @listenTo @programs, "add",    @program.add
    @listenTo @programs, "remove", @program.remove

    @taskChekcer = null

    @render()

    # @listenTo @model.members, "add", @changeMember
    # @members = new GroupMembers()
    # @listenTo @members, "add", @changeMember
    # @listenTo @members, "remove", @changeMember

  program:
    add: (model)->
      console.log "program add"
      console.log model
      # @editor = ace.edit "editor"
      # @editor.setTheme "ace/theme/monokai"
      # @editor.getSession().setMode "ace/mode/javascript"
      # @editor.setValue model.get "program"
      # console.log @editor

    remove: (model)->
      console.log model

  setName: (name)->
    @members.setGroupName name
    @programs.setGroupName name
    console.log App
    App.taskTupleSpace = App.linda.tuplespace("active_task")
    console.log App.taskTupleSpace.watch {group: name}, (err, tuple)=>
      d = tuple.data
      v = ""
      console.log tuple
      if d.status is "eval"
        v = "タスク「#{d.key}」が配信待ちです"
      else if d.status is "receive"
        v = "#{d.id}さんが、タスク「#{d.key}」を実行中です"
      else if d.status is "return"
        v = "#{d.id}さんが、タスク「#{d.key}」を終了しました。"
        v += "返り値は「#{d.value}」です"
      p = $("<p></p>").html v
      $(@.el).find(".task-list").prepend p

  change: (model)->
    console.log "group model change"
    console.log model
    $(@.el).empty()
    # $(@.el).append _.template($("#group-view-member").html())
    #   members: model.get("users").model
    # $(@.el).append _.template($("#group-view-analytics").html())()
    # $(@.el).append _.template($("#group-view-program").html())()
    @render()

  render: ->
    $(@.el).append _.template($("#group-view-member").html())()
    $(@.el).append _.template($("#group-view-analytics").html())()
    $(@.el).append _.template($("#group-view-program").html())()
    $("#main-view").html @.el

  # collection
  reset: (collection)->
    console.log "reset"
    console.log collection

  add: (model)->
    html = _.template($("#group-view-member-element").html())
      id: model.get "id"
    $(@.el).find("tbody.member-list").append html

  remove: (model)->
    tbody = $(@.el).find("tbody.member-list")
    tbody.children().each ->
      u = $(@).find('th.member-id').html()
      a = model.get("id")
      if $(@).find('th.member-id').html() is model.get("id")
        $(@).remove

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
    # @model.get("users").push user
    # @model.save()

  removeMember: (e)->
    e.preventDefault()
    id = $(@.el).parent().find(".member-id").html()
    @members.each (u)=>
      if u.id is id
        @members.remove u
    console.log @members
    @members.save()

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
      group.save()
      App.user.get("groups").push group
      $(@.el).modal('toggle')

class User extends Backbone.Model
  urlRoot: "#{API}/user"

  default:
    login: false

class Users extends Backbone.Collection
  model: User

class GroupModel extends Backbone.Model
  urlRoot: "#{API}/group/"

  initialize: ->
    @members = new GroupMembers()

  parse: (res)->
    _.each res.users, (u)=>
      @members.add new User(u)
    return res

class GroupMembers extends Backbone.Collection
  model: User
  name: ""

  initialize: (name)->
    @setGroupName name

  setGroupName: (name)->
    @name = name
    @url = "#{API}/group/#{name}/member"

  save: (options)->
    Backbone.sync "update", @, options

class ProgramModel extends Backbone.Model
  urlRoot: "#{API}/program/"

  default:
    name: "test"
    program: "function(){\nhogefuga\n}"

class Programs extends Backbone.Collection
  model: ProgramModel

  setGroupName: (name)->
    @url = "#{API}/group/#{name}/programs"

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