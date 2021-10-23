project('com.github.aharotias2.aho-sweeper', 'vala', 'c', version: '0.0.1')

executable(
  'com.github.aharotias2.aho-sweeper',
  files(
    'src/aho-sweeper.vala'
  ),
  dependencies: [
    dependency('gdk-3.0'),
    dependency('gtk+-3.0')
  ],
  install: true,
  install_dir: get_option('prefix') / 'bin'
)

