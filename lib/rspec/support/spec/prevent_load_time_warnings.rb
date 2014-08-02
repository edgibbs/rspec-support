require 'rspec/support/spec/shell_out'

module RSpec::Support::WarningsPrevention
  def files_to_require_for(lib)
    slash         = File::SEPARATOR
    lib_path_re   = %r|#{slash + lib}[^#{slash}]*#{slash}lib|
    load_path     = $LOAD_PATH.grep(lib_path_re).first
    files         = Dir["#{load_path}/**/*.rb"]
    extract_regex = %r|#{Regexp.escape(load_path) + File::SEPARATOR}(.+)\.rb$|

    # We sort to ensure the files are loaded in a consistent order, regardless
    # of OS. Otherwise, it could load in a different order on Travis than
    # locally, and potentially trigger a "circular require considered harmful"
    # warning or similar.
    files.sort.map { |file| file[extract_regex, 1] }
  end
end

RSpec.shared_examples_for "a library that issues no warnings when loaded" do |lib, *preamble_statements|
  include RSpec::Support::ShellOut
  include RSpec::Support::WarningsPrevention

  it "issues no warnings when loaded", :slow do
    # We want to explicitly load every file because each lib has some files that
    # aren't automatically loaded, instead being delayed based on an autoload
    # (such as for rspec-expectations' matchers) or based on a config option
    # (e.g. `config.mock_with :rr` => 'rspec/core/mocking_adapters/rr').
    statements = preamble_statements + files_to_require_for(lib).map do |file|
      "require '#{file}'"
    end

    command = statements.join("; ")

    stdout, stderr, status = run_ruby_with_current_load_path(command, "-w")

    expect(stdout).to eq("")
    expect(stderr).to eq("")
    expect(status.exitstatus).to eq(0)
  end
end