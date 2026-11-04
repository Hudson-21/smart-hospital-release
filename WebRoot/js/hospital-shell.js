(function(){
    'use strict';
    var nav=document.getElementById('nav'),frame=document.getElementById('mainFrame'),sidebar=document.getElementById('sidebar'),fold=document.getElementById('btnFold');
    var icon=window.HospitalUI.icon;
    var icons={'\u533b\u751f\u7ba1\u7406':'hospital','\u75c5\u5e8a\u7ba1\u7406':'bed','\u75c5\u4eba\u7ba1\u7406':'users','\u6536\u8d39\u7ba1\u7406':'wallet','\u6302\u53f7\u7ba1\u7406':'calendar','\u5904\u65b9\u7ba1\u7406':'file','\u7edf\u8ba1\u5206\u6790':'chart','\u667a\u80fd\u670d\u52a1':'chat','\u6211\u7684\u5de5\u4f5c\u53f0':'hospital','\u4e2a\u4eba\u4e2d\u5fc3':'user','\u7cfb\u7edf\u7ba1\u7406':'settings'};
    var links=[];
    function activate(link){
        links.forEach(function(item){item.classList.toggle('active',item===link);if(item===link)item.setAttribute('aria-current','page');else item.removeAttribute('aria-current');});
        document.getElementById('pageTitle').textContent=link.dataset.title;
    }
    function setCollapsed(value){sidebar.classList.toggle('collapsed',value);sidebar.inert=value;fold.setAttribute('aria-expanded',String(!value));}
    function makeLink(title,url,home){
        var a=document.createElement('a');a.className='nav-item';a.href=url;a.target='main';a.dataset.title=title;
        if(home){a.dataset.home='true';a.innerHTML=icon('home');}else{var dot=document.createElement('span');dot.className='dot';a.appendChild(dot);}
        a.appendChild(document.createTextNode(title));
        a.addEventListener('click',function(){activate(a);if(window.matchMedia('(max-width:760px)').matches)setCollapsed(true);});
        links.push(a);return a;
    }
    var home=makeLink('\u5de5\u4f5c\u53f0','right.jsp',true);nav.appendChild(home);activate(home);
    MENUS.forEach(function(group,index){
        var button=document.createElement('button');button.type='button';button.className='nav-group';button.setAttribute('aria-expanded','true');button.setAttribute('aria-controls','nav-group-'+index);
        button.innerHTML='<span class="gi">'+icon(icons[group.name]||'file')+'</span>';
        button.appendChild(document.createTextNode(group.name));
        var arrow=document.createElement('span');arrow.className='arrow';arrow.textContent='\u2304';arrow.setAttribute('aria-hidden','true');button.appendChild(arrow);
        var box=document.createElement('div');box.className='nav-items';box.id='nav-group-'+index;
        group.items.forEach(function(item){box.appendChild(makeLink(item.n,item.u,false));});
        button.addEventListener('click',function(){box.hidden=!box.hidden;button.setAttribute('aria-expanded',String(!box.hidden));});
        nav.appendChild(button);nav.appendChild(box);
    });
    window.HospitalNavigate=function(url){
        var found=links.find(function(a){return a.getAttribute('href')===url;});
        if(found){found.click();return true;}return false;
    };
    fold.setAttribute('aria-controls','sidebar');fold.addEventListener('click',function(){setCollapsed(!sidebar.classList.contains('collapsed'));});
    var mobileQuery=window.matchMedia('(max-width:760px)');
    setCollapsed(mobileQuery.matches);
    function onBreakpointChange(event){setCollapsed(event.matches);}
    if(mobileQuery.addEventListener)mobileQuery.addEventListener('change',onBreakpointChange);
    else mobileQuery.addListener(onBreakpointChange);
    document.addEventListener('keydown',function(e){if(e.key==='Escape'&&window.matchMedia('(max-width:760px)').matches)setCollapsed(true);});
    frame.addEventListener('load',function(){
        try{
            var path=new URL(frame.contentWindow.location.href).pathname;
            if(path.endsWith('/login.jsp')){window.location.href='login.jsp';return;}
            var found=links.find(function(a){return new URL(a.href).pathname===path;});
            if(found)activate(found);
            else if(frame.contentDocument.title)document.getElementById('pageTitle').textContent=frame.contentDocument.title;
        }catch(e){/* The frame may briefly be unavailable during navigation. */}
    });
})();
