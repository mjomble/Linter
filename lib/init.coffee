LinterView = require './linter-view'
StatusBarView = require './statusbar-view'
InlineView = require './inline-view'
# Public: linter package initialization, sets up the linter for usages by atom
class LinterInitializer

  # Internal: Configuration Option defaults
  config:
    lintOnSave:
      type: 'boolean'
      default: true
    lintOnChange:
      type: 'boolean'
      default: true
    lintOnEditorFocus:
      type: 'boolean'
      default: true
    showHighlighting:
      type: 'boolean'
      default: true
    showGutters:
      type: 'boolean'
      default: true
    lintOnChangeInterval:
      type: 'integer'
      default: 1000
    lintDebug:
      type: 'boolean'
      default: false
    showErrorInline:
      type: 'boolean'
      default: true
    statusBar:
      type: 'string'
      default: 'None'
      enum: ['None', 'Show all errors', 'Show error of the selected line', 'Show error if the cursor is in range']

  # Internal: Prevent old deprecated config to be visible in the package settings
  setDefaultOldConfig: ->
    atom.config.restoreDefault('linter.showAllErrorsInStatusBar')
    atom.config.restoreDefault('linter.showErrorInStatusBar')
    atom.config.restoreDefault('linter.showStatusBarWhenCursorIsInErrorRange')

  # Public: Activate the plugin setting up StatusBarView and dicovering linters
  activate: ->
    @setDefaultOldConfig()
    @linterViews = []
    @linters = []

    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implemention = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        @linters.push(require "#{atomPackage.path}/lib/#{implemention}")

    @enabled = true
    @statusBarView = new StatusBarView()
    @inlineView = new InlineView()

    # Subscribing to every current and future editor
    @editorViewSubscription = atom.workspaceView.eachEditorView (editorView) =>
      linterView = @injectLinterViewIntoEditorView(editorView, @statusBarView, @inlineView)
      editorView.editor.on 'grammar-changed', =>
        linterView.initLinters(@linters)
        linterView.lint()
        @linterViews.push(linterView)

  # Internal: add a linter to a new editor view
  injectLinterViewIntoEditorView: (editorView, statusBarView, inlineView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.linterView?

    linterView = new LinterView(editorView, statusBarView, inlineView, @linters)
    linterView

  # Public: deactivate the plugin and unregister all subscriptions
  deactivate: ->
    @editorViewSubscription.off()
    linterView.remove() for linterView in @linterViews
    @inlineView.remove()
    @statusBarView.remove()

module.exports = new LinterInitializer()
