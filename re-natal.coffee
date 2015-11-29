# Re-Natal
# Bootstrap ClojureScript React Native apps
# Dan Motzenbecker
# http://oxism.com
# MIT License

fs      = require 'fs'
net     = require 'net'
http    = require 'http'
crypto  = require 'crypto'
child   = require 'child_process'
cli     = require 'commander'
chalk   = require 'chalk'
semver  = require 'semver'
pkgJson = require __dirname + '/package.json'

nodeVersion     = pkgJson.engines.node
resources       = __dirname + '/resources/'
validNameRx     = /^[A-Z][0-9A-Z]*$/i
camelRx         = /([a-z])([A-Z])/g
projNameRx      = /\$PROJECT_NAME\$/g
projNameHyphRx  = /\$PROJECT_NAME_HYPHENATED\$/g
projNameUsRx    = /\$PROJECT_NAME_UNDERSCORED\$/g
platformRx      = /\$PLATFORM\$/g
rnVersion       = '0.15.0'
rnPackagerPort  = 8081
podMinVersion   = '0.38.2'
process.title   = 're-natal'
sampleCommand  = '(dispatch [:set-greeting "Hello Native World!"])'

log = (s, color = 'green') ->
  console.log chalk[color] s


logErr = (err, color = 'red') ->
  console.error chalk[color] err
  process.exit 1


exec = (cmd, keepOutput) ->
  if keepOutput
    child.execSync cmd
  else
    child.execSync cmd, stdio: 'ignore'


readFile = (path) ->
  fs.readFileSync path, encoding: 'ascii'


edit = (path, pairs) ->
  fs.writeFileSync path, pairs.reduce (contents, [rx, replacement]) ->
    contents.replace rx, replacement
  , readFile path


pluckUuid = (line) ->
  line.match(/\[(.+)\]/)[1]


getUuidForDevice = (deviceName) ->
  device = getDeviceList().find (line) -> line.match deviceName
  unless device
    logErr "Cannot find device `#{deviceName}`"

  pluckUuid device


toUnderscored = (s) ->
  s.replace(camelRx, '$1_$2').toLowerCase()


checkPort = (port, cb) ->
  sock = net.connect {port}, ->
    sock.end()
    http.get "http://localhost:#{port}/status", (res) ->
      data = ''
      res.on 'data', (chunk) -> data += chunk
      res.on 'end', ->
        cb data.toString() isnt 'packager-status:running'

    .on 'error', -> cb true
    .setTimeout 3000

  sock.on 'error', ->
    sock.end()
    cb false


ensureFreePort = (cb) ->
  checkPort rnPackagerPort, (inUse) ->
    if inUse
      logErr "
             Port #{rnPackagerPort} is currently in use by another process
             and is needed by the React Native packager.
             "
    cb()


generateConfig = (name) ->
  log 'Creating Re-Natal config'
  config =
    name:   name
    device: getUuidForDevice 'iPhone 6s'

  writeConfig config
  config


writeConfig = (config) ->
  try
    fs.writeFileSync '.re-natal', JSON.stringify config, null, 2
  catch {message}
    logErr \
      if message.match /EACCES/i
        'Invalid write permissions for creating .re-natal config file'
      else
        message


readConfig = ->
  try
    JSON.parse readFile '.re-natal'
  catch {message}
    logErr \
      if message.match /ENOENT/i
        'No Re-Natal config was found in this directory (.re-natal)'
      else if message.match /EACCES/i
        'No read permissions for .re-natal'
      else if message.match /Unexpected/i
        '.re-natal contains malformed JSON'
      else
        message


getBundleId = (name) ->
  try
    if line = readFile "ios/#{name}.xcodeproj/project.pbxproj"
         .match /PRODUCT_BUNDLE_IDENTIFIER = (.+);/

      line[1]

    else if line = readFile "ios/#{name}/Info.plist"
              .match /\<key\>CFBundleIdentifier\<\/key\>\n?\s*\<string\>(.+)\<\/string\>/

      rfcIdRx = /\$\(PRODUCT_NAME\:rfc1034identifier\)/

      if line[1].match rfcIdRx
        line[1].replace rfcIdRx, name
      else
        line[1]

    else
      throw new Error 'Cannot find bundle identifier in project.pbxproj or Info.plist'

  catch {message}
    logErr message


init = (projName) ->
  if projName.toLowerCase() is 'react' or !projName.match validNameRx
    logErr 'Invalid project name. Use an alphanumeric CamelCase name.'

  projNameHyph = projName.replace(camelRx, '$1-$2').toLowerCase()
  projNameUs   = toUnderscored projName

  try
    log "Creating #{projName}", 'bgMagenta'
    log ''

    if fs.existsSync projNameHyph
      throw new Error "Directory #{projNameHyph} already exists"

    exec 'type lein'
    exec 'type watchman'
    exec 'type xcodebuild'

    log 'Creating Leiningen project'
    exec "lein new #{projNameHyph}"

    log 'Updating Leiningen project'
    process.chdir projNameHyph
    exec "cp #{resources}project.clj project.clj"
    edit \
      'project.clj',
      [
        [projNameHyphRx, projNameHyph]
      ]

    exec "rm -rf resources"

    corePath = "src/#{projNameUs}/core.clj"
    fs.unlinkSync corePath

    handlersPath = "src/#{projNameUs}/handlers.cljs"
    subsPath = "src/#{projNameUs}/subs.cljs"
    exec "cp #{resources}cljs/handlers.cljs #{handlersPath}"
    exec "cp #{resources}cljs/subs.cljs #{subsPath}"

    edit handlersPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName]]
    edit subsPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName]]

    fs.mkdirSync 'src/cljsjs'
    exec "echo '(ns cljsjs.react)' > src/cljsjs/react.cljs"

    fs.mkdirSync "src/#{projNameUs}/android"
    fs.mkdirSync "src/#{projNameUs}/ios"

    coreAndroidPath = "src/#{projNameUs}/android/core.cljs"
    coreIosPath = "src/#{projNameUs}/ios/core.cljs"

    exec "cp #{resources}cljs/core.cljs #{coreAndroidPath}"
    edit coreAndroidPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "android"]]

    exec "cp #{resources}cljs/core.cljs #{coreIosPath}"
    edit coreIosPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "ios"]]

    fs.mkdirSync "env"
    fs.mkdirSync "env/dev"
    fs.mkdirSync "env/dev/env"
    fs.mkdirSync "env/dev/env/ios"
    fs.mkdirSync "env/dev/env/android"
    fs.mkdirSync "env/prod"
    fs.mkdirSync "env/prod/env"
    fs.mkdirSync "env/prod/env/ios"
    fs.mkdirSync "env/prod/env/android"

    mainIosDevPath = "env/dev/env/ios/main.cljs"
    mainIosProdPath = "env/prod/env/ios/main.cljs"
    mainAndroidDevPath = "env/dev/env/android/main.cljs"
    mainAndroidProdPath = "env/prod/env/android/main.cljs"

    exec "cp #{resources}cljs/main_dev.cljs #{mainIosDevPath}"
    edit mainIosDevPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "ios"]]
    exec "cp #{resources}cljs/main_prod.cljs #{mainIosProdPath}"
    edit mainIosProdPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "ios"]]
    exec "cp #{resources}cljs/main_dev.cljs #{mainAndroidDevPath}"
    edit mainAndroidDevPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "android"]]
    exec "cp #{resources}cljs/main_prod.cljs #{mainAndroidProdPath}"
    edit mainAndroidProdPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "android"]]

    requestImgMacroDevPath = "env/dev/env/require_img.clj"
    requestImgMacroProdPath = "env/prod/env/require_img.clj"
    exec "cp #{resources}require_img_dev.clj #{requestImgMacroDevPath}"
    exec "cp #{resources}require_img_prod.clj #{requestImgMacroProdPath}"

    exec "cp -r #{resources}images ."

    log 'Creating React Native skeleton. Relax, this takes a while...'

    fs.writeFileSync 'package.json', JSON.stringify
      name:    projName
      version: '0.0.1'
      private: true
      scripts:
        start: 'node_modules/react-native/packager/packager.sh'
      dependencies:
        'react-native': rnVersion
    , null, 2

    exec 'npm i'

    fs.unlinkSync '.gitignore'
    exec "
           node -e
           \"require('react-native/local-cli/cli').init('.', '#{projName}')\"
           "

    generateConfig projName

    exec "cp #{resources}figwheel-bridge.js ."
    edit "figwheel-bridge.js", [[projNameUsRx, projNameUs]]

    log 'Compiling ClojureScript'
    exec 'lein prod-build'

    log ''
    log 'To get started with your new app, first cd into its directory:', 'yellow'
    log "cd #{projNameHyph}", 'inverse'
    log ''
    log 'Open iOS app in xcode and run it:' , 'yellow'
    log 're-natal xcode', 'inverse'
    log ''
    log 'To use figwheel start "Debug in Chrome" in simulator and type:' , 'yellow'
    log 're-natal use-figwheel', 'inverse'
    log 'lein figwheel ios', 'inverse'
    log ''
    log 'Reload the app in simulator'
    log ''
    log 'At the REPL prompt type this:', 'yellow'
    log "(in-ns '#{projNameHyph}.ios.core)", 'inverse'
    log ''
    log 'Changes you make via the REPL or by changing your .cljs files should appear live.', 'yellow'
    log ''
    log 'Try this command as an example:', 'yellow'
    log sampleCommand, 'inverse'
    log ''
    log '✔ Done', 'bgMagenta'
    log ''

  catch {message}
    logErr \
      if message.match /type.+lein/i
        'Leiningen is required (http://leiningen.org)'
      else if message.match /type.+watchman/i
        'Watchman is required (https://facebook.github.io/watchman)'
      else if message.match /type.+xcodebuild/i
        'Xcode Command Line Tools are required'
      else if message.match /npm/i
        "npm install failed. This may be a network issue. Check #{projNameHyph}/npm-debug.log for details."
      else
        message


launch = ({name, device}) ->
  unless device in getDeviceUuids()
    log 'Device ID not available, defaulting to iPhone 6s simulator', 'yellow'
    {device} = generateConfig name

  try
    fs.statSync 'node_modules'
  catch
    logErr 'Dependencies are missing. Something went horribly wrong...'

  log 'Compiling ClojureScript'
  exec 'lein prod-build'

  log 'Compiling Xcode project'
  try
    exec "
         xcodebuild
         -project ios/#{name}.xcodeproj
         -scheme #{name}
         -destination platform='iOS Simulator',OS=latest,id='#{device}'
         test
         "

    log 'Launching simulator'
    exec "xcrun simctl launch #{device} #{getBundleId name}"

  catch {message}
    logErr message

openXcode = (name) ->
  try
    exec "open ios/#{name}.xcodeproj"
  catch {message}
    logErr \
      if message.match /ENOENT/i
        """
        Cannot find #{name}.xcodeproj in ios.
        Run this command from your project's root directory.
        """
      else if message.match /EACCES/i
        "Invalid permissions for opening #{name}.xcodeproj in ios"
      else
        message


getDeviceList = ->
  try
    exec 'xcrun instruments -s devices', true
      .toString()
      .split '\n'
      .filter (line) -> /^i/.test line
  catch {message}
    logErr 'Device listing failed: ' + message


getDeviceUuids = ->
  getDeviceList().map (line) -> line.match(/\[(.+)\]/)[1]


generateDevScripts = (method) ->
  try
    fs.statSync '.re-natal'
    fs.writeFileSync 'index.ios.js', "require('react-native');require('figwheel-bridge')."+method+"('ios');"
    log 'index.ios.js was regenerated'
    fs.writeFileSync 'index.android.js', "require('react-native');require('figwheel-bridge')."+method+"('android');"
    log 'index.android.js was regenerated'
  catch {message}
    logErr \
      if message.match /EACCES/i
        'Invalid write permissions for creating development scripts'
      else
        message

startRepl = (name, autoChoose) ->
  log 'Starting REPL'
  hasRlwrap =
    try
      exec 'type rlwrap'
      true
    catch
      log '
          Warning: rlwrap is not installed.\nInstall it to make the REPL a much
          better experience with arrow key support.
          ', 'red'
      false

  try
    child.spawn (if hasRlwrap then 'rlwrap' else 'lein'),
      "#{if hasRlwrap then 'lein ' else ''}figwheel ios",
      cwd:   process.cwd()
      env:   process.env
      stdio: 'inherit'

  catch {message}
    logErr message


cli._name = 're-natal'
cli.version pkgJson.version

cli.command 'init <name>'
  .description 'create a new ClojureScript React Native project'
  .action (name) ->
    if typeof name isnt 'string'
      logErr '''
             re-natal init requires a project name as the first argument.
             e.g.
             re-natal init HelloWorld
             '''

    ensureFreePort -> init name


cli.command 'launch'
  .description 'compile project and run in iOS simulator'
  .action ->
    ensureFreePort -> launch readConfig()

cli.command 'listdevices'
  .description 'list available simulator devices by index'
  .action ->
    console.log (getDeviceList()
      .map (line, i) -> "#{i}\t#{line.replace /\[.+\]/, ''}"
      .join '\n')

cli.command 'setdevice <index>'
  .description 'choose simulator device by index'
  .action (index) ->
    unless device = getDeviceList()[parseInt index, 10]
      logErr 'Invalid device index. Run re-natal listdevices for valid indexes.'

    config = readConfig()
    config.device = pluckUuid device
    writeConfig config

cli.command 'xcode'
  .description 'open Xcode project'
  .action ->
    openXcode readConfig().name

cli.command 'deps'
  .description 'install all dependencies for the project'
  .action ->
    try
      log 'Installing npm packages'
      exec 'npm i'
    catch {message}
      logErr message

cli.command 'use-figwheel'
  .description 'generate index.ios.js and index.android.js for development with figwheel'
  .action ->
    generateDevScripts("figwheel")

cli.command 'use-reload'
  .description 'generate index.ios.js and index.android.js for development using app reload'
  .action ->
    generateDevScripts("start")

cli.on '*', (command) ->
  logErr "unknown command #{command[0]}. See re-natal --help for valid commands"


unless semver.satisfies process.version[1...], nodeVersion
  logErr """
         Re-Natal requires Node.js version #{nodeVersion}
         You have #{process.version[1...]}
         """

if process.argv.length <= 2
  cli.outputHelp()
else
  cli.parse process.argv
