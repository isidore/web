
%w(
  start_point_chooser
  start_point_checker
  file_delta_maker
  unit_test_framework_lookup
  git_diff_service
  git_diff_view
  review_file_picker
  ring_picker
  makefile_filter
  output_colour
  dashboard_td_gapper
  display_names_splitter
  host_disk_storer
  runner
  stub_runner
  docker_tar_pipe_runner
).each { |sourcefile| require_relative './' + sourcefile }

