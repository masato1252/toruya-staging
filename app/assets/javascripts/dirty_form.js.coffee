#= require bind_first

UI.define "DirtyFormHandler", ->
  $.fn.DirtyFormHandler = ->
    if @length
      DirtyFormHandler.init()
      @each ->
        new DirtyFormHandler($(@))

  $ -> $(DirtyFormHandler.selector).DirtyFormHandler()

  class DirtyFormHandler
    @selector: "[data-behavior~=dirty-form]"
    @clickLeaving = false
    @instances = []

    @init: =>
      $(window).on "beforeunload", @_beforeunload
      $(window).on "unload", @_unload

    constructor: (@node) ->
      @constructor.instances.push(@)

      @_saveData()
      @node.on "submit", @_submit

    @anyFormDirty: =>
      anyDirty = false
      @instances.forEach (dirtyFormInstance)->
        if dirtyFormInstance._dataChanged()
          anyDirty = true

      anyDirty


    @_unload: =>
      @instances = null

    @_beforeunload: =>
      if !@clickLeaving && @anyFormDirty()
        "Change you made may not be saved"

    _submit: =>
        @constructor.clickLeaving = true

    _saveData: =>
      if !@node.data("serialized")
        @node.data('serialized', @node.find("input:not([data-behavior~=ignore-dirty])").serialize())

    _dataChanged: =>
      @node.data("serialized") != @node.find("input:not([data-behavior~=ignore-dirty])").serialize()

