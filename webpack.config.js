const fs = require('fs')
const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const outputPath = path.join(__dirname, 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const copy = widgetWebpack.getDefaultCopyList()

const entries = {
	'player': [
		path.join(srcPath, 'player.html'),
		path.join(srcPath, 'player.scss'),
		path.join(srcPath, 'player.coffee')
	],
	'creator': [
		path.join(srcPath, 'creator.html'),
		path.join(srcPath, 'creator.scss'),
		path.join(srcPath, 'creator.coffee')
	]
}

const customCopy = copy.concat([
	{
		from: path.join(srcPath, '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	}
])

//options for the build
const options = {
	copyList: customCopy,
	entries: entries
}

let buildConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

module.exports = buildConfig
