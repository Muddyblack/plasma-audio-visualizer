{
  description = "Plasma 6 audio visualizer widget (cava-backed)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
      metadata = builtins.fromJSON (builtins.readFile ./package/metadata.json);
    in {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "plasma-audio-wave-widget";
            version = metadata.KPlugin.Version;
            src = ./package;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              runHook preInstall
              root=$out/share/plasma/plasmoids/org.muddyblack.audioWaveVisualizer
              mkdir -p "$root"
              cp -r . "$root/"
              chmod +x "$root/contents/code/feeder.sh"
              wrapProgram "$root/contents/code/feeder.sh" \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.cava pkgs.util-linux pkgs.procps pkgs.coreutils ]}
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Plasma 6 audio visualizer widget (cava-backed)";
              license = licenses.mit;
              platforms = platforms.linux;
              homepage = "https://github.com/muddyblack/plasma-audio-wave-widget";
            };
          };
        });
    };
}
