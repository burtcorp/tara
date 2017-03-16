versions = {
  '2.1.5' => '20150210',
  '2.1.6' => '20150715',
  '2.2.2' => '20150715',
}
ENV['TRAVELING_RUBY_VERSION'] ||= versions[RUBY_VERSION]
