# Ajoute l'extension WidgetKit « UneWidget » au projet Xcode (une seule fois).
# Usage : ruby tool/add_ios_widget.rb   (nécessite la gem xcodeproj)
require 'xcodeproj'

project_path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'UneWidget' }
  puts 'La cible UneWidget existe déjà.'
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
widget = project.new_target(:app_extension, 'UneWidget', :ios, '16.0', nil, :swift)

group = project.main_group.new_group('UneWidget', 'UneWidget')
swift = group.new_reference('UneWidget.swift')
assets = group.new_reference('Assets.xcassets')
font = group.new_reference('CrimsonText-SemiBold.ttf')
group.new_reference('Info.plist')
xcconfig = group.new_reference('UneWidget.xcconfig')

widget.add_file_references([swift])
widget.add_resources([assets, font])

# Swift lie WidgetKit et SwiftUI tout seul (`import`) : pas de lien explicite,
# dont le chemin dépendrait de la version du SDK installée.
widget.frameworks_build_phase.files.to_a.each do |build_file|
  ref = build_file.file_ref
  build_file.remove_from_project
  ref.remove_from_project if ref && ref.build_files.empty?
end

widget.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'be.lebienheureux.lebienheureux.UneWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'UneWidget/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                  '@executable_path/../../Frameworks']
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
end

# L'app embarque le widget.
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference, true)
  .settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Placée avant « Thin Binary » pour éviter l'erreur de cycle des projets Flutter.
phases = runner.build_phases
phases.delete(embed)
thin = phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
phases.insert(thin || phases.length, embed)

project.save
puts 'Cible UneWidget ajoutée.'
