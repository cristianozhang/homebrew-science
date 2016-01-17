class Superlu43 < Formula
  desc "Solve large sparse nonsymmetric systems of equations"
  homepage "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/"
  url "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_4.3.tar.gz"
  sha256 "169920322eb9b9c6a334674231479d04df72440257c17870aaa0139d74416781"
  revision 1

  bottle do
    cellar :any
    sha256 "4b99c09b1f09394d4a3fe6cf8a768a2b25ae97de5652eeefa26855886cb8ed7b" => :el_capitan
    sha256 "5172668ed872337bf5ce2650f35d518593cc32488c450505b708a513989a0e54" => :yosemite
    sha256 "b1d997c0ebed6661e2937af2bb15937a3b8fa0a03ae853c63acae4cd5ff772ec" => :mavericks
  end

  keg_only "Conflicts with superlu"

  deprecated_option "without-check" => "without-test"

  option "with-matlab", "Build MEX files for use with Matlab"
  option "with-matlab-path=", "Directory that contains MATLAB bin and extern subdirectories"

  option "without-test", "skip build-time tests (not recommended)"
  option "with-openmp", "Enable OpenMP multithreading"

  depends_on :fortran

  # Accelerate single precision is buggy and causes certain single precision
  # tests to fail.
  depends_on "openblas" => ((OS.mac?) ? :optional : :recommended)
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?

  needs :openmp if build.with? "openmp"

  def install
    ENV.deparallelize
    cp "MAKE_INC/make.mac-x", "./make.inc"
    make_args = ["RANLIB=true", "CC=#{ENV.cc}", "CFLAGS=-fPIC #{ENV.cflags}",
                 "FORTRAN=#{ENV.fc}", "FFLAGS=#{ENV.fcflags}",
                 "SuperLUroot=#{buildpath}",
                 "SUPERLULIB=$(SuperLUroot)/lib/libsuperlu.a",
                 "NOOPTS=-fPIC"
                ]

    if build.with? "openblas"
      blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"
    else
      blas = (OS.mac?) ? "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort" : "-lblas"
    end
    make_args << "BLASLIB=#{blas}"
    make_args << ("LOADOPTS=" + ((build.with? "openmp") ? "-fopenmp" : ""))

    system "make", "lib", *make_args
    if build.with? "test"
      system "make", "testing", *make_args
      cd "TESTING" do
        system "make", *make_args
        %w[stest dtest ctest ztest].each do |tst|
          ohai `tail -1 #{tst}.out`.chomp
        end
      end
    end

    cd "EXAMPLE" do
      system "make", *make_args
    end

    if build.with? "matlab"
      matlab = ARGV.value("with-matlab-path") || HOMEBREW_PREFIX
      cd "MATLAB" do
        system "make", "MATLAB=#{matlab}", *make_args
      end
    end

    prefix.install "make.inc"
    File.open(prefix/"make_args.txt", "w") do |f|
      f.puts(make_args.join(" ")) # Record options passed to make.
    end
    lib.install Dir["lib/*"]
    (include/"superlu").install Dir["SRC/*.h"]
    doc.install Dir["Doc/*"]
    (pkgshare/"examples").install Dir["EXAMPLE/*[^.o]"]
    (pkgshare/"matlab").install Dir["MATLAB/*"] if build.with? "matlab"
  end

  def caveats
    s = ""
    if build.with? "matlab"
      s += <<-EOS.undent
        Matlab interfaces are located in

          #{opt_pkgshare}/matlab
      EOS
    end
    s
  end

  test do
    ENV.fortran
    cp_r pkgshare/"examples", testpath
    cp prefix/"make.inc", testpath
    make_args = ["CC=#{ENV.cc}",
                 "CFLAGS=-fPIC #{ENV.cflags}",
                 "FORTRAN=#{ENV.fc}",
                 "FFLAGS=#{ENV.fcflags}",
                 "SuperLUroot=#{opt_prefix}",
                 "SUPERLULIB=#{opt_lib}/libsuperlu.a",
                 "NOOPTS=-fPIC",
                 "HEADER=#{opt_include}/superlu",
                ]

    if build.with? "openblas"
      blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"
    else
      blas = (OS.mac?) ? "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort" : "-lblas"
    end
    make_args << "BLASLIB=#{blas}"
    make_args << ("LOADOPTS=" + ((build.with? "openmp") ? "-fopenmp" : ""))

    cd "examples" do
      system "make", *make_args

      system "./superlu"
      system "./slinsol < g20.rua"
      system "./slinsolx  < g20.rua"
      system "./slinsolx1 < g20.rua"
      system "./slinsolx2 < g20.rua"

      system "./dlinsol < g20.rua"
      system "./dlinsolx  < g20.rua"
      system "./dlinsolx1 < g20.rua"
      system "./dlinsolx2 < g20.rua"

      system "./clinsol < cg20.cua"
      system "./clinsolx < cg20.cua"
      system "./clinsolx1 < cg20.cua"
      system "./clinsolx2 < cg20.cua"

      system "./zlinsol < cg20.cua"
      system "./zlinsolx < cg20.cua"
      system "./zlinsolx1 < cg20.cua"
      system "./zlinsolx2 < cg20.cua"

      system "./sitersol -h < g20.rua"
      system "./sitersol1 -h < g20.rua"
      system "./ditersol -h < g20.rua"
      system "./ditersol1 -h < g20.rua"
      system "./citersol -h < g20.rua"
      system "./citersol1 -h < g20.rua"
      system "./zitersol -h < cg20.cua"
      system "./zitersol1 -h < cg20.cua"
    end
  end
end
