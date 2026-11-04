(function(){
    'use strict';
    var paths={
        home:'<path d="m3 10 9-7 9 7v10H3zM9 20v-7h6v7"/>',
        hospital:'<path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6z"/>',
        users:'<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6M18 15a5 5 0 0 1 3 5"/>',
        calendar:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M7 3v5m10-5v5M3 11h18m-13 5h2m4 0h2"/>',
        bed:'<path d="M3 5v16m18-9v9M3 17h18M3 12h16a2 2 0 0 1 2 2v3M7 8h3v4H7z"/>',
        file:'<path d="M5 3h10l4 4v14H5zM14 3v5h5M9 12h6m-6 4h6"/>',
        chart:'<path d="M3 3v18h18M8 16v-5m5 5V6m5 10V9"/>',
        settings:'<circle cx="12" cy="12" r="3"/><path d="m9 3-1 3-3 1-2 3 2 3v3l3 2 1 3h5l1-3 3-1 2-3-2-3V8l-3-2-1-3z"/>',
        clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
        wallet:'<rect x="3" y="5" width="18" height="15" rx="2"/><path d="M3 8h18m0 5h-5v4h5M6 5V3h12"/>',
        chat:'<path d="M3 4h18v13H9l-6 4zM7 9h10m-10 4h6"/>',
        menu:'<path d="M4 6h16M4 12h16M4 18h16"/>',
        shield:'<path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6zM8 12l3 3 5-6"/>',
        user:'<circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/>',
        arrow:'<path d="m9 5 7 7-7 7"/>'
    };
    function icon(name){return '<svg class="h-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">'+(paths[name]||paths.file)+'</svg>';}
    function decorate(root){(root||document).querySelectorAll('[data-icon]').forEach(function(el){el.innerHTML=icon(el.getAttribute('data-icon'));});}
    window.HospitalUI={icon:icon,decorate:decorate};
    function ready(){
        decorate(document);
        if(!document.body.classList.contains('h-business'))return;
        var heading=document.querySelector('.dqbg');
        if(heading && !heading.closest('form'))heading.classList.add('h-page-heading');
        document.querySelectorAll('.table-border').forEach(function(table){
            var first=table.rows[0];
            if(first && first.cells.length===1 && first.cells[0].classList.contains('tabbg') && !first.textContent.trim() && !first.querySelector('input,button,a'))first.hidden=true;
            if(table.querySelector('th')){
                var wrap=document.createElement('div');wrap.className='h-table-scroll';wrap.tabIndex=0;wrap.setAttribute('role','region');wrap.setAttribute('aria-label',document.title+'\u6570\u636e\u8868\u683c\uff0c\u53ef\u6a2a\u5411\u6eda\u52a8');
                table.parentNode.insertBefore(wrap,table);wrap.appendChild(table);
            }
        });
        document.querySelectorAll('button,input[type=button],input[type=reset],input[type=submit],a').forEach(function(el){
            var label=(el.value||el.textContent||'').replace(/\s/g,'');
            if(/^(\u8fd4\u56de|\u53d6\u6d88|\u91cd\u7f6e|\u5173\u95ed|\u6e05\u7a7a)/.test(label))el.classList.add('h-secondary');
            if(/^(\u5220\u9664|\u4f5c\u5e9f)/.test(label))el.classList.add('h-danger');
        });
        document.querySelectorAll('input[type=image][src$="pic-13.jpg"]').forEach(function(input){
            input.type='button';input.value='\u65b0\u589e';input.removeAttribute('src');input.setAttribute('aria-label','\u65b0\u589e\u8bb0\u5f55');
        });
    }
    if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',ready);else ready();
})();
