# tara

[![Build Status](https://travis-ci.org/mthssdrbrg/tara.svg?branch=master)](https://travis-ci.org/mthssdrbrg/tara)
[![Coverage Status](https://coveralls.io/repos/mthssdrbrg/tara/badge.svg?branch=master)](https://coveralls.io/r/mthssdrbrg/tara?branch=master)
[![Gem Version](https://badge.fury.io/rb/tara.svg)](http://badge.fury.io/rb/tara)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/mthssdrbrg/tara/master/frames)

Tara packs your application into a gzipped TAR archive along with a complete
Ruby runtime and all of the necessary gems.

To accomplish this, Tara uses the already packaged Ruby binaries and native gems
provided by Phusion's Traveling Ruby project.
If you're not familiar with the Traveling Ruby project I encourage you to check
out their [repo](https://github.com/phusion/traveling-ruby) for more information
and motivation on why it exists.

## Installation

Add `tara` to your `Gemfile`, do a simple `bundle install` and you're good to
go:

```ruby
group :development do
  gem 'tara'
end
```

## Requirements

Tara uses Bundler to install your gem's dependecies, and without it Tara won't
work.

Additionally, if you're using gems with native extensions, Tara needs to be able
to download a precompiled version of those gems.
See [Traveling Ruby's tutorial on native extensions](https://github.com/phusion/traveling-ruby/blob/master/TUTORIAL-3.md)
for more information about gems with native extensions and how they work with Traveling Ruby.
Examples of gems with native extensions are `thin`, `eventmachine` and
`sqlite3`.

Tara will automatically find gems with native extensions and attempt to download
a precompiled version. and in the case that the specific version doesn't exist
it'll raise an error and thus refuse to build an archive at all.

## Usage

Tara is currently intended to be used from code, for example in a `Rakefile` or
a `Thor` app, or whatever your preference is.

Below is a minimal code example for creating an archive in a Rake task:

```ruby
task :build do
  Tara::Archive.new.create
end
```

This will package your application into an archive in `build/<app>.tgz`,
including all gems not in the `development` or `test` groups.
By default the created archive will be for Linux x64.
If you want to build it for some other platform, such as Mac OS X, all you have
to do is to pass the `target` option to `Tara::Archive#new`:

```ruby
task :build do
  Tara::Archive.new(target: 'osx').create
end
```

By default Tara will include all Ruby files in `lib`, though it's possible to
override which files that'll be included by passing the `files` option with a
list of globs to `Tara::Archive.new`.

One might run into issues when running Bundler while packaging an application,
and it might be related to the global Bundler configuration.
If that is the case then one can choose to ignore the global Bundler
configuration by passing the `bundle_ignore_config`.

### Executables

Due to how archives are packaged, executables (scripts usually placed in the
`bin` directory) have to be "wrapped" in yet another script that uses the
packaged Ruby library.

Tara will automatically create wrapper scripts for executables in the `bin`
directory, and it'll assume that they are Ruby-only scripts (i.e. not Bash
scripts or whatnot). I'd recommend to use a `#!/usr/bin/env ruby` shebang).

Executables placed at the top-level of a repository is currently not supported,
as it's far from standard and causes some issues when creating the archive as
the wrapper scripts are placed at the top-level of the archive, effectively
overwriting the script that they're wrapping.

At this time it is not possible to supply your own wrapper scripts, but it'll
most likely be possible in future releases.

## Jara compatibility

[Jara](https://github.com/burtcorp/jara) is a tool that creates clean artifacts
from Git repositories and publishes them to S3, and Tara includes an `Archiver`
class that is compatible with Jara.

Using Tara with Jara is as simple as:

```ruby
task :build do
  archiver = Tara::Archiver.new
  releaser = Jarå::Releaser.new('production', 'artifact-bucket', archiver: archiver)
  releaser.release
end
```

The `Archiver` class accepts the same options as the `Archive` class does.

## Copyright

© 2015 Mathias Söderberg, see LICENSE.txt (BSD 3-Clause).

