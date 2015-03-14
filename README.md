# tara

[![Build Status](https://travis-ci.org/mthssdrbrg/tara.svg?branch=master)](https://travis-ci.org/mthssdrbrg/tara)
[![Coverage Status](https://coveralls.io/repos/mthssdrbrg/tara/badge.svg?branch=master)](https://coveralls.io/r/mthssdrbrg/tara?branch=master)

Tara packs your application into a gzipped TAR archive along with a complete
Ruby runtime and all of the necessary gems.

To accomplish this, Tara uses the already packaged Ruby binaries and native gems
provided by Phusion's Traveling Ruby project.
If you're not familiar with the Traveling Ruby project I encourage you to check
out their [repo](https://github.com/phusion/traveling-ruby) for more information
and motivation on why it exists.

## installation

Add `tara` to your `Gemfile`, do a simple `bundle install` and you're good to
go:

```ruby
group :development do
  gem 'tara'
end
```

## requirements

Tara uses Bundler to install your gem's dependecies, and without it Tara won't
work.

Additionally, if you're using gems with native extensions, Tara needs to be able
to download a precompiled version of those gems.
See [Traveling Ruby's tutorial on native extensions](https://github.com/phusion/traveling-ruby/blob/master/TUTORIAL-3.md)
for an overview of native extensions and Traveling Ruby.
Examples of gems with native extensions are `thin`, `eventmachine` and
`sqlite3`.

Tara will automatically find gems with native extensions and attempt to download
a precompiled version, and in the case that the specific version doesn't exist
it'll raise an error, thus refusing to build an archive.

## usage

Tara is currently intended to be used from code, for example in a `Rakefile` or
a `Thor` app, or whatever your preference is.

Minimal code example for creating an archive in a Rake task:

```ruby
task :build do
  Tara::Archive.new.create
end
```

This will package your application into an archive in `build/<app>.tgz`,
including all gems not in the `development` or `test` groups.
The created archive will be for Linux x64.
If you want to build it for some other platform, such as Mac OS X, all you have
to do is to pass the `target` option to `Tara::Archive#new`:

```ruby
task :build do
  Tara::Archive.new(target: 'osx').create
end
```

By default Tara will include all source files in `lib`, and create wrapper
scripts of all files present in `bin`.
The wrapper scripts are needed due to how Tara packages your application and is
just a convenience so that you don't have to bother with it.
To override which files that'll be included pass the `files` option with a list
of globs to `Tara::Archiver#new`.

## copyright

© 2015 Mathias Söderberg, see LICENSE.txt (BSD 3-Clause).

