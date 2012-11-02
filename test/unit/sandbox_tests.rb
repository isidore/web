require File.dirname(__FILE__) + '/../test_helper'

class SandboxTests < ActionController::TestCase

  def setup
    @id = 'ABCDE12345'
    @sandbox = Sandbox.new(root_dir,@id)
  end
  
  def inner_dir
    @id[0..1]
  end
  
  def outer_dir
    @id[2..-1]
  end
  
  def teardown
    if File.exists? @sandbox.dir
      `rm -rf #{@sandbox.dir}`
    end
    @sandbox = nil
  end

  test "creating a new sandbox creates inner and outer subfolders just like katas" do
    @sandbox.make_dir
    inner = root_dir + '/sandboxes/' + inner_dir
    assert File.exists?(inner),
          "File.exists?(#{inner})"
    outer = inner + '/' + outer_dir
    assert File.exists?(outer),
          "File.exists?(#{outer})"    
  end

  test "new sandbox dir reports inner-outer off root_dir-sandboxes" do
    assert_equal root_dir + '/sandboxes/' + inner_dir + '/' + outer_dir,
                 @sandbox.dir
  end
  
  test "saving a file with a folder creates the subfolder and the file in it" do
    filename = 'f1/f2/wibble.txt'
    content = 'Hello world'
    @sandbox.save_file(filename, content)
    pathed_filename = @sandbox.dir + '/' + filename
    assert File.exists?(pathed_filename),
          "File.exists?(#{pathed_filename})"
    assert_equal content, IO.read(pathed_filename)          
  end
  
  test "visible and hidden files are copied to sandbox and output is generated" do
    language = Language.new(root_dir, 'Dummy')
    visible_files = language.visible_files

    @sandbox.make_dir
    output = @sandbox.inner_run(language, visible_files)
    assert File.exists?(@sandbox.dir), "sandbox dir created"
    
    visible_files.each do |filename,content|
      assert File.exists?(@sandbox.dir + '/' + filename),
            "File.exists?(#{@sandbox.dir}/#{filename})"
    end
    
    language.hidden_filenames.each do |filename|
      assert File.exists?(@sandbox.dir + '/' + filename),
            "File.exists?(#{@sandbox.dir}/#{filename})"
    end
    
    assert_match output, /\<54\> expected but was/
  end    
      
  test "sandbox dir is deleted after run" do
    language = Language.new(root_dir, 'Dummy')        
    visible_files = language.visible_files
    output = @sandbox.run(language, visible_files)
    assert_not_nil output, "output != nil"
    assert output.class == String, "output.class == String"
    assert_match output, /\<54\> expected but was/
    assert !File.exists?(@sandbox.dir),
          "!File.exists?(#{@sandbox.dir})"
  end
      
  test "C# files link correctly and not as C files" do
    language = Language.new(root_dir, 'C#')
    visible_files = language.visible_files

    @sandbox.make_dir
    output = @sandbox.inner_run(language, visible_files)
    assert File.exists?(@sandbox.dir), "sandbox dir created"
    
    visible_files.each do |filename,content|
      assert File.exists?(@sandbox.dir + '/' + filename),
            "File.exists?(#{@sandbox.dir}/#{filename})"
    end
    
    language.hidden_filenames.each do |filename|
      assert File.exists?(@sandbox.dir + '/' + filename),
            "File.exists?(#{@sandbox.dir}/#{filename})"
    end    
  end
      
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  test "save file for non executable file" do
    @sandbox.make_dir    
    check_save_file('file.a', 'content', 'content', false)
  end
  
  test "save file for executable file" do
    @sandbox.make_dir    
    check_save_file('file.sh', 'ls', 'ls', true)
  end
  
  test "save file for makefile converts all leading whitespace on a line to a single tab" do
    @sandbox.make_dir    
    check_save_makefile("            abc", "\tabc")
    check_save_makefile("        abc", "\tabc")
    check_save_makefile("    abc", "\tabc")
    check_save_makefile("\tabc", "\tabc")
  end
  
  test "save file for Makefile converts all leading whitespace on a line to a single tab" do
    @sandbox.make_dir    
    check_save_file('Makefile', "            abc", "\tabc", false)
    check_save_file('Makefile', "        abc", "\tabc", false)
    check_save_file('Makefile', "    abc", "\tabc", false)
    check_save_file('Makefile', "\tabc", "\tabc", false)
  end
  
  test "save file for makefile converts all leading whitespace to single tab for all lines in any line format" do
    @sandbox.make_dir    
    check_save_makefile("123\n456", "123\n456")
    check_save_makefile("123\r\n456", "123\n456")
    
    check_save_makefile("    123\n456", "\t123\n456")
    check_save_makefile("    123\r\n456", "\t123\n456")
    
    check_save_makefile("123\n    456", "123\n\t456")
    check_save_makefile("123\r\n    456", "123\n\t456")
    
    check_save_makefile("    123\n   456", "\t123\n\t456")
    check_save_makefile("    123\r\n   456", "\t123\n\t456")
    
    check_save_makefile("    123\n456\n   789", "\t123\n456\n\t789")    
    check_save_makefile("    123\r\n456\n   789", "\t123\n456\n\t789")    
    check_save_makefile("    123\n456\r\n   789", "\t123\n456\n\t789")    
    check_save_makefile("    123\r\n456\r\n   789", "\t123\n456\n\t789")    
  end
  
  def check_save_makefile(content, expected_content)    
    check_save_file('makefile', content, expected_content, false)
  end
      
  def check_save_file(filename, content, expected_content, executable)
    @sandbox.save_file(filename, content)
    pathed_filename = @sandbox.dir + '/' + filename
    assert File.exists?(pathed_filename),
          "File.exists?(#{pathed_filename})"
    assert_equal expected_content, IO.read(pathed_filename)
    assert_equal executable, File.executable?(pathed_filename),
                            "File.executable?(pathed_filename)"
  end
      
end

