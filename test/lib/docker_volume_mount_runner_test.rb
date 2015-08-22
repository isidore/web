#!/usr/bin/env ../test_wrapper.sh lib

require_relative 'lib_test_base'

class DockerVolumeMountRunnerTests < LibTestBase

  def setup
    super
    @bash = BashStub.new
    @cid_filename = 'stub.cid'
    set_disk_class_name     'DiskStub'
    set_git_class_name      'GitSpy'
    set_one_self_class_name 'OneSelfDummy'
    @id = '12345ABCDE'
    kata = make_kata(@id)
    @lion = kata.start_avatar(['lion'])
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'when docker is not installed constructor raises' do
    stub_docker_not_installed
    assert_raises(RuntimeError) { make_docker_runner }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'bash commands run in initialize() do not sudo' do
    stub_docker_installed
    make_docker_runner
    assert @bash.spied[0].start_with?('docker info'), 'docker info'
    assert @bash.spied[1].start_with?('docker images'), 'docker images'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'when docker is installed, image_names determines runnability' do
    stub_docker_installed
    docker = make_docker_runner    
    expected_image_names =
    [
      "cyberdojo/python-3.3.5_pytest",
      "cyberdojo/rust-1.0.0_test"
    ]
    c_assert = languages['C-assert']
    python_py_test = languages['Python-py.test']

    assert_equal expected_image_names, docker.image_names        
    refute docker.runnable?(c_assert);
    assert docker.runnable?(python_py_test);
  end
    
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'started(avatar) is a no-op' do
    stub_docker_installed
    docker = make_docker_runner
    assert_equal 2, @bash.spied.size, 'before'
    docker.started(nil)
    assert_equal 2, @bash.spied.size, 'after'
  end
    
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'pre_test(avatar) is a no-op' do
    stub_docker_installed
    docker = make_docker_runner
    assert_equal 2, @bash.spied.size, 'before'
    docker.pre_test(nil)
    assert_equal 2, @bash.spied.size, 'after'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'exact docker run command to refactor against' do
    stub_docker_installed
    docker = make_docker_runner
    stub_docker_run(completes)
    cmd = 'cyber-dojo.sh'
    docker.run(@lion.sandbox, cmd, max_seconds=5)

    language = @lion.kata.language
    language_path = language.path
    language_volume_mount = language_path + ':' + language_path + ":ro"
    kata_volume_mount = @lion.sandbox.path + ":/sandbox:rw"

    command = "timeout --signal=#{kill} 5s #{cmd} 2>&1"
    expected =
      "timeout --signal=#{kill} 10s" +
        ' docker run' +
          ' --user=www-data' +
          " --cidfile=#{quoted(@cid_filename)}" +
          ' --net=none' +
          " -v #{quoted(language_volume_mount)}" +
          " -v #{quoted(kata_volume_mount)}" +
          ' -w /sandbox' +
          " #{language.image_name}" +
          " /bin/bash -c #{quoted(command)} 2>&1"

    actual = @bash.spied[3]
    assert_equal expected, actual
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'docker run <-> bash interaction when cyber-dojo.sh completes in time' do
    stub_docker_installed
    docker = make_docker_runner
    begin
      stub_docker_run(completes)
      cmd = 'cyber-dojo.sh'
      output = docker.run(@lion.sandbox, cmd, max_seconds=5)      
      assert_equal 'blah',output, 'output'      
      assert_spied(max_seconds, cmd, pid)
    rescue Exception => e  
      p e.message
      @bash.dump
      assert false
    end
  end    
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'docker run <-> bash interaction when cyber-dojo.sh times out' do
    stub_docker_installed
    docker = make_docker_runner
    begin
      stub_docker_run(fatal_error(kill))
      cmd = 'cyber-dojo.sh'
      output = docker.run(@lion.sandbox, cmd, max_seconds=5)      
      assert output.start_with?("Unable to complete the tests in #{max_seconds} seconds."), 'Unable'      
      assert_spied(max_seconds, cmd, pid)
    rescue Exception => e
      p e.message
      @bash.dump    
      assert false
    end
  end
    
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  def assert_spied(max_seconds, cmd, pid)
    run_cmd = @bash.spied[3]
    expected = "timeout --signal=#{kill} #{max_seconds+5}s"
    assert run_cmd.start_with?(expected), 'timeout(outer)'
    expected = "timeout --signal=#{kill} #{max_seconds}s cyber-dojo.sh"
    assert run_cmd.include?(expected), 'timeout(inner)'    
    
    assert run_cmd.include?('docker run'), 'docker run'
    assert run_cmd.include?('--user=www-data'), 'user inside docker container is www-data'
    assert run_cmd.include?("--cidfile="), 'explicit cidfile'
    refute run_cmd.include?('--rm'), 'rm is *not* specified'
    assert run_cmd.include?('-v "/var/www/cyber-dojo/languages'), 'volume mount languages/'
    assert run_cmd.include?('-v "/var/www/cyber-dojo/katas'), 'volume mount katas/'
    assert_equal "docker stop #{pid}", @bash.spied[5], 'docker stop'
    assert_equal "docker rm #{pid}",   @bash.spied[6], 'docker rm'
  end
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
  def make_docker_runner
    DockerVolumeMountRunner.new(@bash,@cid_filename)
  end

end
