{CompositeDisposable} = require 'atom'
helpers = require('atom-linter')

module.exports =
  config:
    executablePath:
      type: 'string'
      title: 'PHP7CC Executable Path'
      default: 'php7cc' # Let OS's $PATH handle the rest

  _testBin: ->
    title = 'linter-php7cc: Unable to determine PHP7CC version'
    message = 'Unable to determine the version of "' + @executablePath +
      '", please verify that this is the right path to PHP7CC.'
    try
      helpers.exec(@executablePath, ['-V']).then (output) =>
        regex = /PHP 7 Compatibility Checker version (\d+)\.(\d+)\.(\d+)/g
        if not regex.exec(output)
          atom.notifications.addError(title, {detail: message})
          @executablePath = ''
      .catch (e) ->
        console.log e
        atom.notifications.addError(title, {detail: message})

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-php7cc.executablePath',
      (executablePath) =>
        @executablePath = executablePath
        @_testBin()

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      name: 'PHP7CC'
      grammarScopes: ['text.html.php', 'source.php']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        command = @executablePath
        return Promise.resolve([]) unless command?
        parameters = []
        parameters.push('--no-interaction')
        parameters.push(textEditor.getPath())
        return helpers.exec(command, parameters, {stdin: ""}).then (output) ->
          regex = /^> Line (\d+):\s+(.+)/gm
          console.log output
          messages = []
          while((match = regex.exec(output)) isnt null)
            messages.push
              type: "Error"
              filePath: filePath
              range: helpers.rangeFromLineNumber(textEditor, match[1] - 1)
              text: match[2]
          messages
