# Re-Natal
# Bootstrap ClojureScript React Native apps
# Dan Motzenbecker
# http://oxism.com
# MIT License

fs      = require 'fs-extra'
fpath   = require 'path'
net     = require 'net'
http    = require 'http'
os      = require 'os'
child   = require 'child_process'
cli     = require 'commander'
chalk   = require 'chalk'
semver  = require 'semver'
ckDeps  = require 'check-dependencies'
pkgJson = require __dirname + '/package.json'

nodeVersion     = pkgJson.engines.node
resources       = __dirname + '/resources'
validNameRx     = /^[A-Z][0-9A-Z]*$/i
camelRx         = /([a-z])([A-Z])/g
projNameRx      = /\$PROJECT_NAME\$/g
projNameHyphRx  = /\$PROJECT_NAME_HYPHENATED\$/g
projNameUsRx    = /\$PROJECT_NAME_UNDERSCORED\$/g
interfaceDepsRx = /\$INTERFACE_DEPS\$/g
platformRx      = /\$PLATFORM\$/g
devHostRx       = /\$DEV_HOST\$/g
ipAddressRx     = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/i
figwheelUrlRx   = /ws:\/\/[0-9a-zA-Z\.]*:/g
appDelegateRx   = /http:\/\/[^:]+/g
rnVersion       = '0.20.0'
rnPackagerPort  = 8081
process.title   = 're-natal'
interfaceConf   =
  'reagent':
    cljsDir: "cljs-reagent"
    sources:
      ios:     ["core.cljs"]
      android: ["core.cljs"]
      common:  ["handlers.cljs", "subs.cljs", "db.cljs"]
      other:   []
    deps:      ['[reagent "0.5.1" :exclusions [cljsjs/react]]'
                '[re-frame "0.6.0"]'
                '[prismatic/schema "1.0.4"]']
    shims:     ["cljsjs.react"]
    sampleCommandNs: '(in-ns \'$PROJECT_NAME_HYPHENATED$.ios.core)'
    sampleCommand: '(dispatch [:set-greeting "Hello Native World!"])'
  'om-next':
    cljsDir: "cljs-om-next"
    sources:
      ios:     ["core.cljs"]
      android: ["core.cljs"]
      common:  ["state.cljs"]
      other:   [["support.cljs","re_natal/support.cljs"]]
    deps:      ['[org.omcljs/om "1.0.0-alpha28" :exclusions [cljsjs/react cljsjs/react-dom]]'
                '[natal-shell "0.1.6"]']
    shims:     ["cljsjs.react", "cljsjs.react.dom"]
    sampleCommandNs: '(in-ns \'$PROJECT_NAME_HYPHENATED$.state)'
    sampleCommand: '(swap! app-state assoc :app/msg "Hello Native World!")'
interfaceNames   = Object.keys interfaceConf
defaultInterface = 'reagent'

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

ensureExecutableAvailable = (executable) ->
  if os.platform() == 'win32'
    try
      exec "where #{executable}"
    catch e
      throw new Error("type: #{executable}: not found")
  else
    exec "type #{executable}"

ensureOSX = (cb) ->
  if os.platform() == 'darwin'
    cb()
  else
    logErr 'This command is only available on OSX'

readFile = (path) ->
  fs.readFileSync path, encoding: 'ascii'


edit = (path, pairs) ->
  fs.writeFileSync path, pairs.reduce (contents, [rx, replacement]) ->
    contents.replace rx, replacement
  , readFile path

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

ensureXcode = (cb) ->
  try
    ensureExecutableAvailable 'xcodebuild'
    cb();
  catch {message}
    if message.match /type.+xcodebuild/i
      logErr 'Xcode Command Line Tools are required'

generateConfig = (interfaceName, projName) ->
  log 'Creating Re-Natal config'
  config =
    name:   projName
    interface: interfaceName
    androidHost: "localhost"
    iosHost: "localhost"
    modules: []
    imageDirs: ["images"]

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

verifyConfig = (config) ->
  if !config.androidHost? || !config.modules? || !config.imageDirs? || !config.interface? || !config.iosHost?
    throw new Error 're-natal project needs to be upgraded, please run: re-natal upgrade'
  config

readConfig = (verify = true)->
  try
    config = JSON.parse readFile '.re-natal'
    if (verify)
      verifyConfig(config)
    else
      config
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

scanImageDir = (dir) ->
  fnames = fs.readdirSync(dir)
    .map (fname) -> "#{dir}/#{fname}"
    .filter (path) -> fs.statSync(path).isFile()
    .map (path) -> path.replace /@2x|@3x/i, ''
    .filter (v, idx, slf) -> slf.indexOf(v) == idx

  dirs = fs.readdirSync(dir)
    .map (fname) -> "#{dir}/#{fname}"
    .filter (path) -> fs.statSync(path).isDirectory()

  fnames.concat scanImages(dirs)

scanImages = (dirs) ->
  imgs = []
  for dir in dirs
    imgs = imgs.concat(scanImageDir(dir));
  imgs

configureDevHostForAndroidDevice = (deviceType) ->
  try
    allowedTypes = {'real': 'localhost', 'avd': '10.0.2.2', 'genymotion': '10.0.3.2'}
    devHost = allowedTypes[deviceType]
    if (! devHost?)
      throw new Error "Unknown android device type #{deviceType}, known types are #{Object.keys(allowedTypes)}"
    log "Using host '#{devHost}' for android device type '#{deviceType}'"
    config = readConfig()
    config.androidHost = devHost
    writeConfig(config)
  catch {message}
    logErr message

resolveIosDevHost = (deviceType) ->
  if deviceType == 'simulator'
    log "Using 'localhost' for iOS simulator"
    'localhost'
  else if deviceType == 'real'
    en0Ip = exec('ipconfig getifaddr en0', true).toString().trim()
    log "Using IP of interface en0:'#{en0Ip}' for real iOS device"
    en0Ip
  else if deviceType.match(ipAddressRx)
    log "Using development host IP: '#{deviceType}'"
    deviceType
  else
    log("Value '#{deviceType}' is not a valid IP address, still configured it as development host for iOS", 'yellow')
    deviceType

configureDevHostForIosDevice = (deviceType) ->
  try
    devHost = resolveIosDevHost(deviceType)
    config = readConfig()
    config.iosHost = devHost
    writeConfig(config)
  catch {message}
    logErr message

copyDevEnvironmentFiles = (interfaceName, projNameHyph, projName, devHost) ->
  fs.mkdirpSync "env/dev/env/ios"
  fs.mkdirpSync "env/dev/env/android"

  userNsPath = "env/dev/user.clj"
  fs.copySync("#{resources}/user.clj", userNsPath)

  mainIosDevPath = "env/dev/env/ios/main.cljs"
  mainAndroidDevPath = "env/dev/env/android/main.cljs"

  cljsDir = interfaceConf[interfaceName].cljsDir
  fs.copySync("#{resources}/#{cljsDir}/main_dev.cljs", mainIosDevPath)
  edit mainIosDevPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "ios"], [devHostRx, devHost] ]
  fs.copySync("#{resources}/#{cljsDir}/main_dev.cljs", mainAndroidDevPath)
  edit mainAndroidDevPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "android"], [devHostRx, devHost]]

copyProdEnvironmentFiles = (interfaceName, projNameHyph, projName) ->
  fs.mkdirpSync "env/prod/env/ios"
  fs.mkdirpSync "env/prod/env/android"

  mainIosProdPath = "env/prod/env/ios/main.cljs"
  mainAndroidProdPath = "env/prod/env/android/main.cljs"

  cljsDir = interfaceConf[interfaceName].cljsDir
  fs.copySync("#{resources}/#{cljsDir}/main_prod.cljs", mainIosProdPath)
  edit mainIosProdPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "ios"]]
  fs.copySync("#{resources}/#{cljsDir}/main_prod.cljs", mainAndroidProdPath)
  edit mainAndroidProdPath, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, "android"]]

copyFigwheelBridge = (projNameUs) ->
  fs.copySync("#{resources}/figwheel-bridge.js", "./figwheel-bridge.js")
  edit "figwheel-bridge.js", [[projNameUsRx, projNameUs]]

updateGitIgnore = () ->
  fs.appendFileSync(".gitignore", "\n# Generated by re-natal\n#\nindex.android.js\nindex.ios.js\ntarget/\n")
  fs.appendFileSync(".gitignore", "\n# Figwheel\n#\nfigwheel_server.log")

patchReactNativePackager = () ->
  ckDeps.sync {install: true, verbose: false}
  log "Patching react-native packager to serve *.map files"
  edit "node_modules/react-native/packager/react-packager/src/Server/index.js",
    [[/match.*\.map\$\/\)/m, "match(/index\\..*\\.map$/)"]]

shimCljsNamespace = (ns) ->
  filePath = "src/" + ns.replace(/\./g, "/") + ".cljs"
  fs.mkdirpSync fpath.dirname(filePath)
  fs.writeFileSync(filePath, "(ns #{ns})")

copySrcFiles = (interfaceName, projName, projNameUs, projNameHyph) ->
  cljsDir = interfaceConf[interfaceName].cljsDir

  fileNames = interfaceConf[interfaceName].sources.common;
  for fileName in fileNames
    path = "src/#{projNameUs}/#{fileName}"
    fs.copySync("#{resources}/#{cljsDir}/#{fileName}", path)
    edit path, [[projNameHyphRx, projNameHyph], [projNameRx, projName]]

  platforms = ["ios", "android"]
  for platform in platforms
    fs.mkdirSync "src/#{projNameUs}/#{platform}"
    fileNames = interfaceConf[interfaceName].sources[platform]
    for fileName in fileNames
      path = "src/#{projNameUs}/#{platform}/#{fileName}"
      fs.copySync("#{resources}/#{cljsDir}/#{fileName}", path)
      edit path, [[projNameHyphRx, projNameHyph], [projNameRx, projName], [platformRx, platform]]

  otherFiles = interfaceConf[interfaceName].sources.other;
  for cpFile in otherFiles
    from = "#{resources}/#{cljsDir}/#{cpFile[0]}"
    to = "src/#{cpFile[1]}"
    fs.copySync(from, to)

  shims = fileNames = interfaceConf[interfaceName].shims;
  for namespace in shims
    shimCljsNamespace(namespace)

copyProjectClj = (interfaceName, projNameHyph) ->
  fs.copySync("#{resources}/project.clj", "project.clj")
  deps = interfaceConf[interfaceName].deps.join("\n")
  edit 'project.clj', [[projNameHyphRx, projNameHyph], [interfaceDepsRx, deps]]

init = (interfaceName, projName) ->
  if projName.toLowerCase() is 'react' or !projName.match validNameRx
    logErr 'Invalid project name. Use an alphanumeric CamelCase name.'

  projNameHyph = projName.replace(camelRx, '$1-$2').toLowerCase()
  projNameUs   = toUnderscored projName

  try
    log "Creating #{projName}", 'bgMagenta'
    log ''

    if fs.existsSync projNameHyph
      throw new Error "Directory #{projNameHyph} already exists"

    ensureExecutableAvailable 'lein'

    log 'Creating Leiningen project'
    exec "lein new #{projNameHyph}"

    log 'Updating Leiningen project'
    process.chdir projNameHyph
    fs.removeSync "resources"
    corePath = "src/#{projNameUs}/core.clj"
    fs.unlinkSync corePath

    copyProjectClj(interfaceName, projNameHyph)

    copySrcFiles(interfaceName, projName, projNameUs, projNameHyph)

    fs.mkdirSync "env"

    copyDevEnvironmentFiles(interfaceName, projNameHyph, projName, "localhost")
    copyProdEnvironmentFiles(interfaceName, projNameHyph, projName)

    fs.copySync("#{resources}/images", "./images")

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
    exec "node -e
           \"require('react-native/local-cli/cli').init('.', '#{projName}')\"
           "

    updateGitIgnore()

    generateConfig(interfaceName, projName)

    copyFigwheelBridge(projNameUs)

    log 'Compiling ClojureScript'
    exec 'lein prod-build'

    log ''
    log 'To get started with your new app, first cd into its directory:', 'yellow'
    log "cd #{projNameHyph}", 'inverse'
    log ''
    log 'Open iOS app in xcode and run it:' , 'yellow'
    log 're-natal xcode', 'inverse'
    log ''
    log 'To use figwheel type:' , 'yellow'
    log 're-natal use-figwheel', 'inverse'
    log 'lein figwheel ios', 'inverse'
    log ''
    log 'Reload the app in simulator'
    log ''
    log 'At the REPL prompt type this:', 'yellow'
    log interfaceConf[interfaceName].sampleCommandNs.replace(projNameHyphRx, projNameHyph), 'inverse'
    log ''
    log 'Changes you make via the REPL or by changing your .cljs files should appear live.', 'yellow'
    log ''
    log 'Try this command as an example:', 'yellow'
    log interfaceConf[interfaceName].sampleCommand, 'inverse'
    log ''
    log '✔ Done', 'bgMagenta'
    log ''

  catch {message}
    logErr \
      if message.match /type.+lein/i
        'Leiningen is required (http://leiningen.org)'
      else if message.match /npm/i
        "npm install failed. This may be a network issue. Check #{projNameHyph}/npm-debug.log for details."
      else
        message

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

generateRequireModulesCode = (modules) ->
  jsCode = "var modules={'react-native': require('react-native')};"
  for m in modules
    jsCode += "modules['#{m}']=require('#{m}');";
  jsCode += '\n'

updateFigwheelUrls = (androidHost, iosHost) ->
  mainAndroidDevPath = "env/dev/env/android/main.cljs"
  edit mainAndroidDevPath, [[figwheelUrlRx, "ws://#{androidHost}:"]]

  mainIosDevPath = "env/dev/env/ios/main.cljs"
  edit mainIosDevPath, [[figwheelUrlRx, "ws://#{iosHost}:"]]

updateIosAppDelegate = (projName, iosHost) ->
  appDelegatePath = "ios/#{projName}/AppDelegate.m"
  edit appDelegatePath, [[appDelegateRx, "http://#{iosHost}"]]

generateDevScripts = () ->
  try
    config = readConfig()
    projName = config.name

    depState = ckDeps.sync {install: false, verbose: false}
    if (!depState.depsWereOk)
      throw new Error "Missing dependencies, please run: re-natal deps"

    log 'Cleaning...'
    exec 'lein clean'

    images = scanImages(config.imageDirs).map (fname) -> './' + fname;
    modulesAndImages = config.modules.concat images;
    moduleMap = generateRequireModulesCode modulesAndImages

    androidDevHost = config.androidHost
    iosDevHost = config.iosHost

    fs.writeFileSync 'index.ios.js', "#{moduleMap}require('figwheel-bridge').withModules(modules).start('#{projName}','ios','#{iosDevHost}');"
    log 'index.ios.js was regenerated'
    fs.writeFileSync 'index.android.js', "#{moduleMap}require('figwheel-bridge').withModules(modules).start('#{projName}','android','#{androidDevHost}');"
    log 'index.android.js was regenerated'

    updateIosAppDelegate(projName, iosDevHost)
    log "AppDelegate.m was updated"

    updateFigwheelUrls(androidDevHost, iosDevHost)
    log 'Dev server host for iOS: ' + iosDevHost
    log 'Dev server host for Android: ' + androidDevHost

  catch {message}
    logErr \
      if message.match /EACCES/i
        'Invalid write permissions for creating development scripts'
      else
        message

doUpgrade = (config) ->
  projName = config.name;
  projNameHyph = projName.replace(camelRx, '$1-$2').toLowerCase()
  projNameUs   = toUnderscored projName

  unless config.interface
    config.interface = defaultInterface

  unless config.modules
    config.modules = []

  unless config.imageDirs
    config.imageDirs = ["images"]

  unless config.androidHost
    config.androidHost = "localhost"

  unless config.iosHost
    config.iosHost = "localhost"

  writeConfig(config)
  log 'upgraded .re-natal'

  interfaceName = config.interface;

  copyDevEnvironmentFiles(interfaceName, projNameHyph, projName, "localhost")
  copyProdEnvironmentFiles(interfaceName, projNameHyph, projName)
  log 'upgraded files in env/'

  copyFigwheelBridge(projNameUs)
  log 'upgraded figwheel-bridge.js'

  edit "src/#{projNameUs}/ios/core.cljs", [[/\^:figwheel-load\s/g, ""]]
  edit "src/#{projNameUs}/android/core.cljs", [[/\^:figwheel-load\s/g, ""]]
  log 'upgraded core.cljs'

  edit '.gitignore', [[/^\s*env\/dev\s*$/m, ""]]
  gignore = readFile '.gitignore'
  if (!gignore.match /^\s*target\/\s*$/m)
    fs.appendFileSync(".gitignore", "\ntarget/\n")
  log 'upgraded .gitignore'

useComponent = (name) ->
  log "Component '#{name}' is now configured for figwheel, please re-run 'use-figwheel' command to take effect"
  try
    config = readConfig()
    config.modules.push name
    writeConfig(config)
  catch {message}
    logErr message

cli._name = 're-natal'
cli.version pkgJson.version

cli.command 'init <name>'
  .description 'create a new ClojureScript React Native project'
  .option "-i, --interface [#{interfaceNames.join ' '}]", 'specify React interface', defaultInterface
  .action (name, cmd) ->
    if typeof name isnt 'string'
      logErr '''
             re-natal init requires a project name as the first argument.
             e.g.
             re-natal init HelloWorld
             '''
    unless interfaceConf[cmd.interface]
      logErr "Unsupported React interface: #{cmd.interface}, one of [#{interfaceNames}] was expected."
    ensureFreePort -> init(cmd.interface, name)

cli.command 'upgrade'
.description 'upgrades project files to current installed version of re-natal (the upgrade of re-natal itself is done via npm)'
.action ->
  doUpgrade readConfig(false)

cli.command 'xcode'
  .description 'open Xcode project'
  .action ->
    ensureOSX ->
      ensureXcode ->
        openXcode readConfig().name

cli.command 'deps'
  .description 'install all dependencies for the project'
  .action ->
    ckDeps.sync {install: true, verbose: true}

cli.command 'use-figwheel'
  .description 'generate index.ios.js and index.android.js for development with figwheel'
  .action () ->
    generateDevScripts()

cli.command 'use-android-device <type>'
  .description 'sets up the host for android device type: \'real\' - localhost, \'avd\' - 10.0.2.2, \'genymotion\' - 10.0.3.2'
  .action (type) ->
    configureDevHostForAndroidDevice type

cli.command 'use-ios-device <type>'
  .description 'sets up the host for ios device type: \'simulator\' - localhost, \'device\' - auto detect IP on eth0, IP'
  .action (type) ->
    configureDevHostForIosDevice type

cli.command 'use-component <name>'
  .description 'configures a custom component to work with figwheel. name is the value you pass to (js/require) function.'
  .action (name) ->
    useComponent(name)

cli.command 'enable-source-maps'
.description 'patches RN packager to server *.map files from filesystem, so that chrome can download them.'
.action () ->
  patchReactNativePackager()

cli.command 'copy-figwheel-bridge'
  .description 'copy figwheel-bridge.js into project'
  .action () ->
    copyFigwheelBridge(readConfig(false).name)
    log "Copied figwheel-bridge.js"

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
