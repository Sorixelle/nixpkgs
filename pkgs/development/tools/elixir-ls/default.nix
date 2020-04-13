{ stdenv, fetchFromGitHub, lib, erlang, elixir, git, cacert }:

let
  name = "elixir-ls";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "elixir-lsp";
    repo = name;
    rev = "v${version}";
    sha256 = "1wv2rcccdfixc2mxsqajfh9634f13dzrfq0zrskn5iwgnnwlc8vm";
  };

  src-with-deps = stdenv.mkDerivation {
    name = "${name}-src-with-deps";

    nativeBuildInputs = [ elixir erlang git cacert ];

    inherit src;

    configurePhase = ''
      mkdir -p __home
      export HOME=$(pwd)/__home
    '';

    buildPhase = ''
      mix local.hex --force
      mix local.rebar --force
      mix deps.get
    '';

    installPhase = ''
      patchShebangs $HOME/.mix/rebar{,3}
      cp -r . $out
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "0y9l7iv69l1q17vqk23kj5drwg00f79ycrf0b5n7g46aamwhlnjd";
  };
in stdenv.mkDerivation rec {
  inherit name version;

  src = src-with-deps;

  nativeBuildInputs = [ git erlang ];
  buildInputs = [ elixir ];

  configurePhase = ''
    export HOME=$(pwd)/__home
  '';

  buildPhase = ''
    mix compile
  '';

  installPhase = ''
    mkdir -p $out/bin
    mix elixir_ls.release -o $out/bin
    sed -i 's|elixir|${elixir}/bin/elixir|' $out/bin/language_server.sh
    ln -s language_server.sh $out/bin/elixir-ls
  '';

  meta = with lib; {
    description = "A frontend-independent IDE \"smartness\" server for Elixir.";
    homepage = https://github.com/elixir-lsp/elixir-ls;
    license = licenses.asl20;
    maintainers = with maintainers; [ sorixelle ];
    platforms = platforms.unix;
  };
}
