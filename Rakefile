task :default => [:compile, :docs]
  
task :compile do
  system "coffee -clo compiled src/jquery.expand.coffee"
  system "closure --compilation_level SIMPLE_OPTIMIZATIONS < compiled/jquery.expand.js > compiled/jquery.expand.min.js"
end

task :docs do
  system "docco src/*.coffee"
end

task :update_gh_pages => :docs do
  system "cp -r docs __updates__"
  system "git co gh-pages"
  system "cp __updates__/* ."
  system "mv jquery.expand.html index.html"
  system "rm -rf __updates__"
end
