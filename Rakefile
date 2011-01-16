task :default => [:compile, :docs]
  
task :compile do
  system "coffee -clo compiled src/jquery.expand.coffee"
  system "closure --compilation_level SIMPLE_OPTIMIZATIONS < compiled/jquery.expand.js > compiled/jquery.expand.min.js"
end

task :docs do
  system "docco src/*.coffee"
end
