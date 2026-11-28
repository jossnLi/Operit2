/* Minimal HIG-style line icon set + inline sprite injection.
   Usage: <i data-ic="chevright" data-s="20"></i>  or  <i data-ic="check" class="ic"></i> */
(function () {
  var P = {
    chevleft: '<path d="M15 4.5 7.6 12 15 19.5"/>',
    chevright: '<path d="M9 4.5 16.4 12 9 19.5"/>',
    chevdown: '<path d="M5.5 9 12 15.5 18.5 9"/>',
    chevup: '<path d="M5.5 15 12 8.5 18.5 15"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    check: '<path d="M5 12.6 9.4 17 19 7.4"/>',
    checkcircle: '<circle cx="12" cy="12" r="8.6"/><path d="M8.2 12.4l2.6 2.6 5-5.4"/>',
    x: '<path d="M6.4 6.4 17.6 17.6M17.6 6.4 6.4 17.6"/>',
    search: '<circle cx="10.8" cy="10.8" r="6.3"/><path d="M15.6 15.6 20 20"/>',
    more: '<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>',
    morev: '<circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/>',
    key: '<circle cx="8" cy="12" r="3.2"/><path d="M11.2 12h9.6M17.8 12v3.2"/>',
    user: '<circle cx="12" cy="8.4" r="3.7"/><path d="M4.7 19.4c1.3-4 4-6.1 7.3-6.1s6 2.1 7.3 6.1"/>',
    shield: '<path d="M12 3.2l7 2.9v5.9c0 4.5-2.9 7.6-7 8.8-4.1-1.2-7-4.3-7-8.8V6.1z"/><path d="M8.9 12.2l2.2 2.2 4-4.2"/>',
    alert: '<path d="M12 4.2l8.4 14.8H3.6z"/><path d="M12 9.6v3.9"/><circle cx="12" cy="16.2" r=".9" fill="currentColor" stroke="none"/>',
    info: '<circle cx="12" cy="12" r="8.6"/><path d="M12 11v5"/><circle cx="12" cy="8" r=".95" fill="currentColor" stroke="none"/>',
    refresh: '<path d="M19.8 12a7.8 7.8 0 1 1-2.4-5.6"/><path d="M19.9 4.3v4.2h-4.2"/>',
    spark: '<path d="M12 3.4l1.9 5.1 5.1 1.9-5.1 1.9L12 17.4l-1.9-5.1L5 10.4l5.1-1.9z"/><path d="M18.6 15.6l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z"/>',
    bolt: '<path d="M13.4 3.2 5.6 13.4h4.9l-.9 7.4 7.8-10.2h-4.9z"/>',
    clock: '<circle cx="12" cy="12" r="8.4"/><path d="M12 7.4V12l3.2 2"/>',
    globe: '<circle cx="12" cy="12" r="8.4"/><path d="M3.6 12h16.8M12 3.6c2.4 2.3 3.6 5.2 3.6 8.4s-1.2 6.1-3.6 8.4c-2.4-2.3-3.6-5.2-3.6-8.4s1.2-6.1 3.6-8.4z"/>',
    external: '<path d="M14.2 4.4H19.6v5.4"/><path d="M19.6 4.4 11 13"/><path d="M18.4 13.6v4.6a2 2 0 0 1-2 2H6.2a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4.6"/>',
    trash: '<path d="M4.4 7.2h15.2"/><path d="M9.4 7.2V4.8h5.2v2.4"/><path d="M6.6 7.2l.8 12.1a1.7 1.7 0 0 0 1.7 1.5h5.8a1.7 1.7 0 0 0 1.7-1.5l.8-12.1"/>',
    eye: '<path d="M2.6 12S6.2 6.8 12 6.8 21.4 12 21.4 12 17.8 17.2 12 17.2 2.6 12 2.6 12z"/><circle cx="12" cy="12" r="2.7"/>',
    copy: '<rect x="8.6" y="8.6" width="11" height="11" rx="2.6"/><path d="M15.4 5.6a2 2 0 0 0-2-2H6.4a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2"/>',
    tune: '<path d="M4 7.4h7.6M16.6 7.4h3.4M4 16.6h3.4M12.4 16.6h7.6"/><circle cx="14.1" cy="7.4" r="2.4"/><circle cx="9.9" cy="16.6" r="2.4"/>',
    layers: '<path d="M12 3.4 3.6 7.6 12 11.8 20.4 7.6z"/><path d="M3.6 12.2 12 16.4l8.4-4.2"/><path d="M3.6 16.6 12 20.8l8.4-4.2"/>',
    wifi: '<path d="M4.6 11.6a10.4 10.4 0 0 1 14.8 0"/><path d="M7.8 15a6.4 6.4 0 0 1 8.4 0"/><circle cx="12" cy="18.4" r="1.1" fill="currentColor" stroke="none"/>',
    wifioff: '<path d="M4.6 11.6a10.4 10.4 0 0 1 14.8 0"/><path d="M7.8 15a6.4 6.4 0 0 1 8.4 0"/><circle cx="12" cy="18.4" r="1.1" fill="currentColor" stroke="none"/><path d="M4.4 19.6 19.6 4.4"/>',
    lock: '<rect x="4.8" y="10.4" width="14.4" height="9.6" rx="2.6"/><path d="M8.2 10.4V8a3.8 3.8 0 0 1 7.6 0v2.4"/>',
    grid: '<rect x="4.4" y="4.4" width="6.4" height="6.4" rx="1.6"/><rect x="13.2" y="4.4" width="6.4" height="6.4" rx="1.6"/><rect x="4.4" y="13.2" width="6.4" height="6.4" rx="1.6"/><rect x="13.2" y="13.2" width="6.4" height="6.4" rx="1.6"/>',
    chart: '<path d="M4.4 19.6h15.2"/><path d="M7.4 16.4V11M12 16.4V6.6M16.6 16.4v-6"/>',
    arrowup: '<path d="M12 19.4V5M6.2 10.8 12 5l5.8 5.8"/>',
    arrowupright: '<path d="M7 17 17 7"/><path d="M9.4 7h7.6v7.6"/>',
    play: '<path d="M8.2 5.6 18 12l-9.8 6.4z"/>',
    stop: '<rect x="6.4" y="6.4" width="11.2" height="11.2" rx="2"/>',
    edit: '<path d="M11.2 5.4H6.2a2 2 0 0 0-2 2v10.4a2 2 0 0 0 2 2h10.4a2 2 0 0 0 2-2v-5"/><path d="M16.6 4.2l3.2 3.2-7.6 7.6-3.6.6.6-3.6z"/>',
    phone: '<rect x="6.8" y="3" width="10.4" height="18" rx="2.6"/><path d="M10.6 18.2h2.8"/>',
    browser: '<rect x="3.6" y="4.6" width="16.8" height="14.8" rx="2.4"/><path d="M3.6 8.6h16.8"/><circle cx="6.6" cy="6.6" r=".8" fill="currentColor" stroke="none"/>',
    code: '<path d="M8.4 8 4.4 12l4 4M15.6 8l4 4-4 4"/>',
    model: '<rect x="4.4" y="4.4" width="15.2" height="15.2" rx="4.2"/><circle cx="12" cy="12" r="2.9"/>',
    gauge: '<path d="M4.6 16.4a8.2 8.2 0 1 1 14.8 0"/><path d="M12 12.6l3.4-3.2"/><circle cx="12" cy="16.4" r="1.4"/>',
    coin: '<circle cx="12" cy="12" r="8.4"/><path d="M12 7.6v8.8M9.6 9.8h4.8M9.6 14.2h4.8"/>',
    puzzle: '<path d="M10 4.2a2 2 0 0 1 4 0v2h2.4a1.6 1.6 0 0 1 1.6 1.6V11h-2a2 2 0 0 0 0 4h2v3.2a1.6 1.6 0 0 1-1.6 1.6H13.6v-2a2 2 0 0 0-4 0v2H7.2a1.6 1.6 0 0 1-1.6-1.6v-3.2h2a2 2 0 0 0 0-4h-2v-3.2A1.6 1.6 0 0 1 7.2 6.2H10z"/>',
    filter: '<path d="M4.4 6.4h15.2M7 12h10M10 17.6h4"/>',
    minus: '<path d="M5.4 12h13.2"/>',
    browserdot: '<circle cx="12" cy="12" r="9"/><path d="M12 7.4v4.8l3.2 2"/>',
    logout: '<path d="M14.4 4.6h3.6a2 2 0 0 1 2 2v10.8a2 2 0 0 1-2 2h-3.6"/><path d="M10 8 6 12l4 4M6 12h9.4"/>',
    login: '<path d="M10 4.6H6.4a2 2 0 0 0-2 2v10.8a2 2 0 0 0 2 2H10"/><path d="M14.6 8 18.6 12l-4 4M18.6 12H9"/>',
    /* —— 场景补充：服务端点 / 连接测试 / 默认标记 / 功能分流 / 模型目录 —— */
    server: '<rect x="4.2" y="4.6" width="15.6" height="6.2" rx="2"/><rect x="4.2" y="13.2" width="15.6" height="6.2" rx="2"/><circle cx="7.8" cy="7.7" r=".9" fill="currentColor" stroke="none"/><circle cx="7.8" cy="16.3" r=".9" fill="currentColor" stroke="none"/>',
    flask: '<path d="M9.6 3.6h4.8"/><path d="M10.6 3.6v5.2L5.8 18.1a1.9 1.9 0 0 0 1.7 2.7h9a1.9 1.9 0 0 0 1.7-2.7L13.4 8.8V3.6"/><path d="M7.9 14.6h8.2"/>',
    star: '<path d="M12 4.1 14.5 9.4l5.8.8-4.2 4.1 1 5.8L12 17.4l-5.1 2.7 1-5.8L3.7 10.2l5.8-.8z"/>',
    branch: '<circle cx="6.6" cy="5.8" r="2.3"/><circle cx="6.6" cy="18.2" r="2.3"/><circle cx="17.6" cy="12" r="2.3"/><path d="M6.6 8.1v7.8"/><path d="M9 5.8h3.6a3 3 0 0 1 3 3v1"/><path d="M9 18.2h3.6a3 3 0 0 0 3-3v-1"/>',
    database: '<ellipse cx="12" cy="6.2" rx="7" ry="2.9"/><path d="M5 6.2v5.6c0 1.6 3.1 2.9 7 2.9s7-1.3 7-2.9V6.2"/><path d="M5 11.8v5.6c0 1.6 3.1 2.9 7 2.9s7-1.3 7-2.9v-5.6"/>',
    link: '<path d="M10.4 13.6a3.7 3.7 0 0 0 5.2 0l2.3-2.3a3.7 3.7 0 0 0-5.2-5.2l-1 1"/><path d="M13.6 10.4a3.7 3.7 0 0 0-5.2 0l-2.3 2.3a3.7 3.7 0 0 0 5.2 5.2l1-1"/>',
    /* —— 语义补充：对话 / 图像 / 音频 / 视频 / 记忆 / 翻译 / 标题 / 摘要 / 目录 / 多人 / 步骤 / 端点 / 导出 / 历史 / 帮助 / 隐藏 —— */
    message: '<path d="M6.8 4.8h10.4a3 3 0 0 1 3 3v6.2a3 3 0 0 1-3 3H10.2l-3.6 3v-3H6.8a3 3 0 0 1-3-3V7.8a3 3 0 0 1 3-3z"/>',
    image: '<rect x="3.8" y="5" width="16.4" height="14" rx="2.8"/><circle cx="8.7" cy="9.7" r="1.4"/><path d="M4.2 16.6l4.5-4.4 4.1 3.9 3-2.9 3.8 4.1"/>',
    audio: '<path d="M4.4 10.4v3.2M8 7.2v9.6M11.6 9.4v5.2M15.2 6.2v11.6M18.8 10.2v3.6"/>',
    video: '<rect x="3.6" y="6.6" width="12.6" height="10.8" rx="2.6"/><path d="M16.2 11.2l3.8-2.2v6l-3.8-2.2z"/>',
    cpu: '<rect x="6.8" y="6.8" width="10.4" height="10.4" rx="2.4"/><path d="M9.9 3.8v3M14.1 3.8v3M9.9 17.2v3M14.1 17.2v3M3.8 9.9h3M3.8 14.1h3M17.2 9.9h3M17.2 14.1h3"/>',
    translate: '<path d="M4.4 4.8h8M8.4 3v1.8c0 4.6-1.5 7.4-3.8 9.2"/><path d="M3.4 13.4h9.6"/><path d="M13.6 20.4l3.7-8.6 3.7 8.6M14.9 17.6h4.8"/>',
    tag: '<path d="M11.2 3.8H6.4a2.6 2.6 0 0 0-2.6 2.6v4.8l8.4 8.4a2.6 2.6 0 0 0 3.7 0l4.8-4.8a2.6 2.6 0 0 0 0-3.7z"/><circle cx="8.2" cy="8.2" r="1.3"/>',
    compress: '<path d="M9.8 4.4v5.4H4.4M14.2 4.4v5.4h5.4M9.8 19.6v-5.4H4.4M14.2 19.6v-5.4h5.4"/>',
    list: '<path d="M8.6 6.4h11M8.6 12h11M8.6 17.6h11"/><circle cx="4.9" cy="6.4" r="1.15"/><circle cx="4.9" cy="12" r="1.15"/><circle cx="4.9" cy="17.6" r="1.15"/>',
    users: '<circle cx="9.3" cy="9" r="2.9"/><path d="M4.2 19c.8-3.3 2.8-5 5.1-5s4.3 1.7 5.1 5"/><path d="M15.4 6.4a2.7 2.7 0 0 1 0 5.2"/><path d="M16.6 14.4c1.7.5 2.8 2.1 3.2 4.4"/>',
    route: '<circle cx="6.2" cy="6.2" r="2.2"/><circle cx="17.8" cy="17.8" r="2.2"/><path d="M8.4 6.2h4.2a3.2 3.2 0 0 1 0 6.4H10a3.2 3.2 0 0 0 0 6.4h5.6"/>',
    plug: '<path d="M9 3.6v4.6M15 3.6v4.6"/><path d="M6.6 8.2h10.8v2.2a5.4 5.4 0 0 1-10.8 0z"/><path d="M12 15.8v4.6"/>',
    download: '<path d="M12 4.2v10.8M7.6 10.6 12 15l4.4-4.4"/><path d="M4.6 19.4h14.8"/>',
    history: '<path d="M4.4 12a7.6 7.6 0 1 0 2.4-5.5"/><path d="M4.1 5.1v4.2h4.2"/><path d="M12 8.2V12l2.9 1.7"/>',
    help: '<circle cx="12" cy="12" r="8.5"/><path d="M9.7 9.5a2.4 2.4 0 0 1 4.7.8c0 1.7-2.4 1.9-2.4 3.5"/><circle cx="12" cy="17.2" r=".95" fill="currentColor" stroke="none"/>',
    eyeoff: '<path d="M3.4 12S6.9 6.9 12 6.9c1.4 0 2.8.4 4 1"/><path d="M20.6 12s-3.5 5.1-8.6 5.1c-1.4 0-2.8-.4-4-1"/><path d="M4.2 19.8 19.8 4.2"/>',
    percent: '<path d="M6.4 17.6 17.6 6.4"/><circle cx="7.6" cy="7.6" r="2.2"/><circle cx="16.4" cy="16.4" r="2.2"/>',
    limit: '<path d="M5 18.6h14"/><path d="M12 4.8v9.8"/><path d="M8.6 11 12 14.4l3.4-3.4"/>',
    doc: '<path d="M13.4 3.8H7.4a2.4 2.4 0 0 0-2.4 2.4v11.6a2.4 2.4 0 0 0 2.4 2.4h9.2a2.4 2.4 0 0 0 2.4-2.4V9.2z"/><path d="M13.4 3.8v5.4h5.4"/><path d="M8.6 12.6h6.8M8.6 16h4.6"/>',
    wrench: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>'
  };

  function build(name, size, stroke) {
    var body = P[name] || P.info;
    return '<svg viewBox="0 0 24 24" width="' + size + '" height="' + size +
      '" fill="none" stroke="currentColor" stroke-width="' + stroke +
      '" stroke-linecap="round" stroke-linejoin="round">' + body + '</svg>';
  }
  window.IC = build;

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('[data-ic]').forEach(function (el) {
      var size = Number(el.getAttribute('data-s') || 20);
      var stroke = Number(el.getAttribute('data-w') || 1.7);
      el.innerHTML = build(el.getAttribute('data-ic'), size, stroke);
      el.style.display = 'inline-flex';
      el.style.alignItems = 'center';
      el.style.justifyContent = 'center';
      el.style.flex = 'none';
    });
  });
})();
