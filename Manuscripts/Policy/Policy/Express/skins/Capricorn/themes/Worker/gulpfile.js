/// <vs Clean='clean' />
var gulp = require('gulp');
var sass = require('gulp-dart-sass');	//sass support
var cleanCSS = require('gulp-clean-css');	//css minimizer/optimizer
var eslint = require('gulp-eslint');	//javascript linting
var uglify = require('gulp-uglify');	//javascript minimizing/optimizer
var del = require('del');				//helps delete directories
var plumber = require('gulp-plumber');	//handle errors
var autoprefixer = require('gulp-autoprefixer');	//add vendor specific css rules as necessary
var saveLicense = require('uglify-save-license');	//preserve license statements when minimizing
var header = require('gulp-header');	//auto inject headers onto files
var moment = require('moment');	//date/time support library
var concat = require('gulp-concat');	//concatenate files into one
var chmod = require('gulp-chmod'); // manage file permissions
var gulpif = require('gulp-if');	//conditionally run gulp tasks
var rename = require('gulp-rename');
var watch = require('gulp-watch');	//command line arguments
var fontName = 'dctIcons';
var runTimestamp = Math.round(Date.now() / 1000);
var runSequence = require('run-sequence');	//syncronus tasks in gulp
var meta = {};
var build = moment().format('YYYYMMDD-kkmmss');
var year = moment().format('YYYY');
var sourcemaps = require('gulp-sourcemaps');
var banner = ['/*!',
	'Copyright <%=year %> Duck Creek Technologies, LLC. All rights reserved.',
	' @build <%=build %>',
	' */\n\n',
	''].join(' ') + '\n';


meta = require('./build.json');
meta.sourcepath = './';
meta.workerthemefontsourcepath = './fonts';
meta.workerthemesourcepath = './css';

// build tasks for worker theme
gulp.task('build-worker-theme-css', function () {
	return gulp.src([meta.workerthemesourcepath + '/main.scss'])
		.pipe(sourcemaps.init())
		.pipe(plumber({
			errorHandler: sass.logError
		}))
		.pipe(chmod(0777))
		.pipe(sass.sync({ outputStyle: 'expanded' }))
		.pipe(autoprefixer({
			browsers: ['last 2 versions'],
			cascade: true
		}))
		.pipe(header(banner, { meta: meta, build: build, year: year }))
		.pipe(rename('theme-debug.css'))
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest(meta.workerthemesourcepath));
});

gulp.task('minify-worker-css', gulp.series('build-worker-theme-css', function () {
	return gulp.src([meta.workerthemesourcepath + '/main.scss'])
		.pipe(sourcemaps.init())
		.pipe(plumber({
			errorHandler: sass.logError
		}))
		.pipe(chmod(0777))
		.pipe(sass.sync({ outputStyle: 'expanded' }))
		.pipe(autoprefixer({
			browsers: ['last 2 versions'],
			cascade: true
		}))
		.pipe(header(banner, { meta: meta, build: build, year: year }))
		.pipe(cleanCSS({ compatibility: 'ie11' }))
		.pipe(rename('theme.css'))
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest(meta.workerthemesourcepath));
}));

/* build-responsive */
gulp.task('default', gulp.series('minify-worker-css'));

// build tasks for building the glyph icon set
gulp.task('buildglyph', function () {
	var iconfont = require('gulp-iconfont'); // creates icon glyph set
	var iconfontCss = require('gulp-iconfont-css'); // creates the variables and styles for icon glyph set

	return gulp.src([meta.workerthemefontsourcepath + '/icon-source/*.svg'])
		.pipe(iconfontCss({
			fontName: fontName,
			path: meta.workerthemefontsourcepath + '/icon-source/_glyph-icons.scss',
			targetPath: '../css/base/_glyph-icons.scss',
			cssClass: 'icon',
			timestamp: runTimestamp
		}))
		.pipe(iconfont({
			fontName: fontName,
			formats: ['ttf', 'eot', 'woff', 'woff2', 'svg'],
			normalize: true,
			centerHorizontally: true,
			fixedWidth: true,
			fontHeight: 1001,
			prependUnicode: false,
			timestamp: runTimestamp
		}))
		.pipe(gulp.dest(meta.workerthemefontsourcepath));
});

gulp.task('buildglyphvars', function () {
	var iconfontCss = require('gulp-iconfont-css'); // creates the variables and styles for icon glyph set
	return gulp.src([meta.workerthemefontsourcepath + '/icon-source/*.svg'])
		.pipe(iconfontCss({
			fontName: fontName,
			path: meta.workerthemefontsourcepath + '/icon-source/_glyph-variables.scss',
			targetPath: '../css/abstracts/_glyph-variables.scss',
			cssClass: 'icon',
			timestamp: runTimestamp
		}))
		.pipe(gulp.dest(meta.workerthemefontsourcepath));
});


gulp.task('clean:fonts', function () {
	return del([meta.workerthemefontsourcepath + '/dct*.*'], { force: true });
});

gulp.task('clean:fonttemp', function () {
	return del([meta.workerthemefontsourcepath + '/u*.svg'], { force: true });
});

gulp.task('updatefont', gulp.series('clean:fonts', gulp.series('buildglyphvars', 'buildglyph'), 'clean:fonttemp'));


// Watch Files For Changes
gulp.task('watch', function () {
	gulp.watch(meta.workerthemesourcepath + '/**/*.scss', ['default']);
	gulp.watch(['./**/*.scss', '!./**/_glyph-*.scss'], ['default']);
});
