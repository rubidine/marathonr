require 'rubygems'
require 'test/spec'

context 'Given Command Line Arugments' do
  setup do
    # TODO make this more complete
    ::ARGV = ['-n', '30']
  end

  it 'should report those arguments as non-defaults' do
  end

  it 'should report those arguments as non-defaults (even when same as defaults)' do
  end

  it 'should change configuration for each given option' do
  end
end

context 'Given a Config File' do
  setup do
    # TODO WRITE FILE
  end

  it 'should load arguments and report them as non-defaults' do
  end
end

context 'Given a Config File and Command Line Arguments' do
  setup do
    # TODO set ::ARGV and write a config file
  end

  it 'config file should not overwrite command-line options' do
  end

  it 'should supress loading of config file with command line arguments' do
  end
  
  it 'should be able to load config file from a nonstandard location by arugment' do
  end
end
