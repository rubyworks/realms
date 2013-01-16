=begin
When '# Use Command' do
  complete_setup
end

When '# Insert Command' do
  #FileUtils.rm_r('tmp') if File.exist?('tmp')
  copy_fixture('project_setup')
end

When '# Out Command' do
  complete_setup
end

When '# Show Command' do
  complete_setup
end

When '# Show List' do
  complete_setup
end

When '# List Command' do
  complete_setup
end

When '# Sync Command' do
  complete_setup
end

When '# Verify Command' do
  complete_setup
end

When '# Path Command' do
  complete_setup
end

When '# Where Command' do
  complete_setup
end
=end
