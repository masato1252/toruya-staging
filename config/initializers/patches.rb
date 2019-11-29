# Load on patches in lib/patches.

Dir[Rails.root.join("lib", "patches", "**", "*.rb")].each do |patch_file|
  require Pathname.new(patch_file)
end
