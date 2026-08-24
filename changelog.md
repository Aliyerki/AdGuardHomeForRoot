## 20260824

Fork con correcciones para el corte de DNS al arrancar.

- `tool.sh` espera a que AdGuardHome escuche de verdad en `redir_port` antes de
  aplicar las reglas iptables. Antes se redirigía el puerto 53 en el mismo
  segundo en que se lanzaba el binario, dejando el dispositivo sin DNS durante
  todo el arranque del resolutor (~40 s en un Redmi Note 11). Esa ventana hacía
  fallar la comprobación de conectividad de Android, que marcaba la red como
  "sin internet"; el navegador y Google Play se negaban a usarla hasta forzar
  una revalidación a mano con el modo avión.
- Si el listener no llega a tiempo (`startup_timeout`, 120 s por defecto), se
  omiten las reglas iptables en lugar de dejar el dispositivo sin DNS.
- El bloqueo de DNS IPv6 usa `REJECT` en vez de `DROP`, para que el cliente
  caiga a IPv4 de inmediato en vez de esperar el timeout completo (issue #71).
- Upstreams por defecto: Cloudflare y Google sobre DoH con IP literal, sin
  depender del bootstrap.
- Zona horaria por defecto `America/Mexico_City`.
