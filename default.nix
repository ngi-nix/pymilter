{
  pkgs,
  inShell ? false
}:
pkgs.python3Packages.buildPythonPackage {
  pname = "pymilter";
  version = "1.0.5";
  src = if inShell then null else ./.;
  propagatedBuildInputs = [ pkgs.libmilter ];
  
  nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.unzip pkgs.patchelf pkgs.zip];
  postBuild = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
        echo "Executing a post build hook on darwin systems to solve a dynamic linker issue"
        cd dist/
        echo "Unzip pymilter-1.0.5-cp39-cp39-darwin_x86_64.whl" >&2
        unzip pymilter-1.0.5-cp39-cp39-darwin_x86_64.whl -d pymilter-1.0.5-cp39-cp39-darwin_x86_64
        cd pymilter-1.0.5-cp39-cp39-darwin_x86_64
        echo "Set the rpath to ${pkgs.libmilter}/lib" >&2
        pathelf --set-rpath ${pkgs.libmilter}/lib milter.cpython-39-darwin.so
        echo "Zip pymilter-1.0.5-cp39-cp39-darwin_x86_64.whl" >&2
        zip -r pymilter-1.0.5-cp39-cp39-darwin_x86_64.whl ./
        mv pymilter-1.0.5-cp39-cp39-darwin_x86_64.whl ../
        cd ..
        rm -rf pymilter-1.0.5-cp39-cp39-darwin_x86_64
        cd ..
        echo "End of the postBuild hook"
      '';

  # FYI: here is what works on Linux
  # postBuild = ''
  #     echo "Executing a post build hook on darwin systems to solve a dynamic linker issue"
  #     cd dist/
  #     echo "Unzip pymilter-1.0.5-cp39-cp39-linux_x86_64.whl" >&2
  #     unzip pymilter-1.0.5-cp39-cp39-linux_x86_64.whl -d pymilter-1.0.5-cp39-cp39-linux_x86_64
  #     cd pymilter-1.0.5-cp39-cp39-linux_x86_64
  #     echo "Set the rpath to ${pkgs.libmilter}/lib" >&2
  #     patchelf --set-rpath ${pkgs.libmilter}/lib milter.cpython-39-x86_64-linux-gnu.so
  #     echo "Zip pymilter-1.0.5-cp39-cp39-linux_x86_64.whl" >&2
  #     zip -r pymilter-1.0.5-cp39-cp39-linux_x86_64.whl ./
  #     mv pymilter-1.0.5-cp39-cp39-linux_x86_64.whl ../
  #     cd ..
  #     rm -rf pymilter-1.0.5-cp39-cp39-linux_x86_64
  #     cd ..
  #     echo "End of the postBuild hook"
  #   '';

  doCheck = false;  # to avoid the missing `makemap` executable of Sendmail
  pythonImportsCheck = [ "Milter" ];
  meta = {
    homepage = https://github.com/sdgathman/pymilter;
    description = ''
      A python extension module to enable python scripts to attach to Sendmail's libmilter API, enabling filtering of messages as they arrive. Since it's a script, you can do anything you want to the message - screen out viruses, collect statistics, add or modify headers, etc. You can, at any point, tell Sendmail to reject, discard, or accept the message.

      Additional python modules provide for navigating and modifying MIME parts, and sending DSNs or doing CBVs.'';
    license = pkgs.lib.licenses.gpl2Only;
  };
}
