# Host Woodland Watch from your Windows laptop

The laptop runs the Godot game servers and serves the browser version. The title screen lists **Fern Creek** and **Lantern Hollow**. Each public room hosts a squad of up to six and saves its own campaign progress. Friends who choose the same room play together.

## 1. Start the game on your laptop

1. Double-click `Start Online Host.cmd`. It looks for the Godot and Node.js already on this PC. If it asks for Godot, drag your Godot console executable onto the launcher. [Download Node.js](https://nodejs.org/)
2. Open `http://127.0.0.1:8080` in Chrome or Edge and choose **Join Fern Creek** or **Join Lantern Hollow**. Two players who choose the same room will see each other.

To publish a change you made in Godot, export the **Web** preset again to `build/web/index.html` and restart the launcher. Keep the files generated beside `index.html` together.

Leave the launcher open and keep the laptop awake and online during play. Press **Ctrl+C** in the hosting window to stop the server.

## 2. Give friends a browser link

With the game host running, double-click `Share Online Playtest.cmd`. The launcher uses Cloudflare's Windows executable from `build/tools/cloudflared.exe`. If you move the source without the build folder, download the Windows executable there. [Download Cloudflare's tool](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/)

Share the HTTPS address ending in `trycloudflare.com` and your room's name. Anyone with the address can join either room. The address changes when the tunnel restarts. Press **Ctrl+C** in the sharing window to take the public link offline. [Cloudflare Quick Tunnels](https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/)

For a reusable link, create a named Cloudflare Tunnel with a domain in your Cloudflare account and publish your chosen hostname to `http://127.0.0.1:8080`. The browser automatically connects to the same hostname for online play. Share that single address with Windows, iPhone, and Android players. Cloudflare can also publish the root domain directly. If you move the site, export browser progress before switching addresses and import it at the new address. Windows players can use **Join by Address** with the new HTTPS link. [Cloudflare Tunnel setup](https://developers.cloudflare.com/tunnel/get-started/)

The tunnel connects out from your laptop, so you can leave your router and inbound firewall settings as they are. Your players only need the game link and a compatible browser. [Cloudflare Tunnel overview](https://developers.cloudflare.com/tunnel/)

Desktop players can enter the host's browser address under **Join Co-op** for Fern Creek. Add `/play/lantern-hollow` to the address to join Lantern Hollow from the desktop client.
