task :default => [:compile, :docs]
  
desc "recompile"
task :compile do
  system "coffee -co compiled src/jquery.expand.coffee"
  system "closure --compilation_level SIMPLE_OPTIMIZATIONS < compiled/jquery.expand.js > compiled/jquery.expand.min.js"
end

desc "relint"
task :lint do
  system "coffee -l src/jquery.expand.coffee"
end

desc "generate documentation"
task :docs do
  system "rocco src/*.coffee"
end

desc "update github pages"
task :update_gh_pages => :docs do
  system "cp -r docs __updates__"
  system "git co gh-pages"
  system "cp __updates__/* ."
  system "mv jquery.expand.html index.html"
  system "rm -rf __updates__"
end
