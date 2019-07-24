const fs = require('fs')
const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const outputPath = path.join(__dirname, 'build') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const copy = widgetWebpack.getDefaultCopyList()

const entries = {
	'player.js': [
			path.join(srcPath, 'player.coffee')
	],
	'creator.js': [
			path.join(srcPath, 'creator.coffee')
	],
	'player.css': [
			path.join(srcPath, 'player.html'),
			path.join(srcPath, 'player.scss')
	],
	'creator.css': [
			path.join(srcPath, 'creator.html'),
			path.join(srcPath, 'creator.scss')
	],
	'guides/player.temp.html': [
			path.join(srcPath, '_guides', 'player.md')
	],
	'guides/creator.temp.html': [
			path.join(srcPath, '_guides', 'creator.md')
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
