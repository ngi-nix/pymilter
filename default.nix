{
  stdenv,
  lib,
  libmilter,
  unzip,
  patchelf,
  zip,
  libredirect,
  inShell ? false,
  # python dependencies
  buildPythonPackage,
  pydns,
  bsddb3,
}:
buildPythonPackage {
  pname = "pymilter";
  version = "1.0.4";
  src = if inShell then null else ./.;
  propagatedBuildInputs = [
    libmilter
    # A dependency of Milter/dns.py
    pydns
  ];
  postPatch = ''
    # NB: all other files have a try: import thread; except: import _thread
    substituteInPlace Milter/greylist.py --replace 'import thread' 'import _thread'
    substituteInPlace setup.py --replace "from distutils.core import setup, Extension" "from setuptools import setup, Extension"
    substituteInPlace Milter/config.py --replace "from ConfigParser import ConfigParser" "from configparser import ConfigParser"
    substituteInPlace Milter/dsn.py --replace "from email.Message import Message" "from email.message import EmailMessage"
    substituteInPlace Milter/dsn.py --replace "from email.Message import message" "from email.message import EmailMessage"
    substituteInPlace Milter/dsn.py --replace "import dns" "import Milter.dns as dns"
    '';
  nativeBuildInputs = lib.optionals stdenv.isDarwin [ unzip zip];
  postInstall = lib.optionalString stdenv.isDarwin ''
    find ./ -name "*.so" -print0 -exec install_name_tool -change libmilter.dylib ${libmilter}/lib/libmilter.dylib {} \;
    find $out -name "*.so" -print0 -exec install_name_tool -change libmilter.dylib ${libmilter}/lib/libmilter.dylib {} \;
  '';
  checkInputs = [ bsddb3 ];
  # CheckPhase needs an access to a dummy /etc/resolv.conf
  #   https://nixos.wiki/wiki/Packaging/Quirks_and_Caveats
  preCheck = lib.optionalString stdenv.isLinux ''
    echo "nameserver 127.0.0.1" > resolv.conf
    export NIX_REDIRECTS=/etc/resolv.conf=$(realpath resolv.conf) \
    LD_PRELOAD=${libredirect}/lib/libredirect.so
  '';
  # FIXME: use tox during the checkPhase
  #   https://github.com/pypa/setuptools/issues/1684
  checkPhase = ''
    runHook preCheck
    python setup.py test
    runHook postCheck
  '';
  postCheck = "unset NIX_REDIRECTS LD_PRELOAD";
  doCheck = true;
  pythonImportsCheck = [ "Milter" ];
  meta = {
    homepage = https://github.com/sdgathman/pymilter;
    description = ''
      A python extension module to enable python scripts to attach to Sendmail's libmilter API, enabling filtering of messages as they arrive. Since it's a script, you can do anything you want to the message - screen out viruses, collect statistics, add or modify headers, etc. You can, at any point, tell Sendmail to reject, discard, or accept the message.

      Additional python modules provide for navigating and modifying MIME parts, and sending DSNs or doing CBVs.'';
    license = lib.licenses.gpl2Only;
  };
}
