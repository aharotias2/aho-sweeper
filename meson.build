project('com.github.aharotias2.aho-sweeper', 'vala', 'c', version: '0.0.1')

executable(
  meson.project_name(),
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

install_data(
  ['etc/@0@.desktop'.format(meson.project_name())],
  install_dir: get_option('prefix') / 'share/applications'
)
