require File.dirname(__FILE__) + '/test_helper.rb'

class TestYamler < Test::Unit::TestCase

  def setup
    @test_path = File.join(File.dirname(__FILE__),"yamler_test.yml")
    @test_path2 = File.join(File.dirname(__FILE__),"yamler_test2.yml")
  end
  
  def teardown
    File.unlink @test_path if File.exists?(@test_path)
    File.unlink @test_path2 if File.exists?(@test_path2)
  end
  
  def test_init
    Yamler.new @test_path
    assert File.exists?(@test_path)
  end
  
  def test_setter
    @obj = Yamler.new @test_path
    @obj.name = "nick merwin"
    @obj.title = "programmer"
    
    assert_equal "nick merwin", @obj.name
    assert_equal "programmer", @obj.title
    
    assert_equal "nick merwin", @obj['name']
    assert_equal "programmer", @obj['title']
    
    begin
      @obj.blah 
    rescue 
      assert_equal NoMethodError, $!.class
    end
  end
  
  def test_save
    @obj = Yamler.new @test_path
    @obj.name = "nick merwin"
    
    @obj.save
    
    @obj2 = Yamler.new @test_path
    assert_equal  "nick merwin", @obj2.name
  end
  
  def test_block
    Yamler.new @test_path do |obj|
      obj.name = "nick merwin"
    end
    
    @obj = Yamler.new @test_path
    assert_equal  "nick merwin", @obj.name
  end
  
  def test_type
    @obj = Yamler.new @test_path
    assert_equal Hash, @obj.attributes.class
    
    @obj2 = Yamler.new @test_path2, Array
    assert_equal Array, @obj2.attributes.class
    
    @obj2 << 1
    assert_equal 1, @obj2.first
  end
  
  def test_yamlize_array
    a = [].yamlize @test_path
    
    a << 1
    a.save
    
    # test some array functions
    b = [].yamlize @test_path
    assert_equal 1, b.first
    assert_equal [2], b.map{|i| i+1}
    
    b << 1
    b.uniq!
    assert_equal [1], b.attributes
  end
  
  def test_yamlize_hash
    a = {}.yamlize @test_path
    
    a.first = 1
    a.save
    
    b = {}.yamlize @test_path
    assert_equal 1, b.first
  end
  
end
