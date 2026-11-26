(function () {
  'use strict';
  var doctors = window.hospitalBookingDoctors;
  var preset = window.hospitalBookingPreset;
  var form = document.getElementById('f1');
  var department = document.getElementById('kebie');
  var doctor = document.getElementById('doctor');
  var date = document.getElementById('riqi');
  var shift = document.getElementById('shiftInp');
  var box = document.getElementById('shiftBox');
  var submit = document.getElementById('submitBtn');
  var revision = 0;
  var loading = false;
  var submitting = false;
  var activeRequest = null;

  function updateSubmit() {
    submit.disabled = loading || submitting || !shift.value;
  }

  function fillDoctors(selected) {
    doctor.options.length = 0;
    doctor.add(new Option('--请选择--', ''));
    doctors.forEach(function (entry) {
      if (entry[1] === department.value) doctor.add(new Option(entry[0], entry[0]));
    });
    doctor.value = selected || '';
    loadShifts();
  }

  function renderShifts(shifts) {
    box.textContent = '';
    ['上午', '下午'].forEach(function (name) {
      var info = shifts.find(function (item) { return item.shift === name; });
      var option = document.createElement('button');
      var available = info && info.remain > 0;
      option.type = 'button';
      option.className = 'shift-cell' + (available ? '' : ' disabled');
      option.dataset.shift = name;
      option.disabled = !available;
      option.textContent = name;
      option.setAttribute('aria-pressed', 'false');
      var label = document.createElement('span');
      label.className = 'num';
      label.textContent = (!info ? '未排班' : (!available ? '已约满' : '余 ' + info.remain)) + ' / ' + (info ? info.total : 0);
      option.appendChild(label);
      option.addEventListener('click', function () {
        if (loading || submitting || option.disabled || !box.contains(option)) return;
        Array.prototype.forEach.call(box.querySelectorAll('.shift-cell'), function (button) {
          button.classList.toggle('sel', button === option);
          button.setAttribute('aria-pressed', button === option ? 'true' : 'false');
        });
        shift.value = name;
        updateSubmit();
      });
      box.appendChild(option);
    });
  }

  function loadShifts() {
    var ticket = ++revision;
    if (activeRequest) activeRequest.abort();
    activeRequest = null;
    shift.value = '';
    loading = Boolean(department.value && doctor.value && date.value);
    updateSubmit();
    if (!loading) {
      box.textContent = '请先选医生与日期';
      return;
    }
    box.textContent = '查询中…';
    var params = new URLSearchParams({kebie: department.value, doctor: doctor.value, date: date.value});
    var request = new XMLHttpRequest();
    activeRequest = request;
    request.open('GET', 'paiban_shift_api.jsp?' + params.toString());
    request.timeout = 8000;
    function fail() {
      if (ticket !== revision) return;
      loading = false;
      activeRequest = null;
      box.textContent = '号源查询失败，请重试。 ';
      var retry = document.createElement('button');
      retry.type = 'button';
      retry.textContent = '重试';
      retry.addEventListener('click', loadShifts);
      box.appendChild(retry);
      updateSubmit();
    }
    request.onload = function () {
      if (ticket !== revision) return;
      if (request.status !== 200) { fail(); return; }
      try {
        var result = JSON.parse(request.responseText);
        if (!Array.isArray(result.shifts)) { fail(); return; }
        renderShifts(result.shifts);
        loading = false;
        activeRequest = null;
        updateSubmit();
      } catch (error) { fail(); }
    };
    request.onerror = fail;
    request.ontimeout = fail;
    request.send();
  }

  var departments = [];
  doctors.forEach(function (entry) {
    if (entry[1] && departments.indexOf(entry[1]) === -1) {
      departments.push(entry[1]);
      department.add(new Option(entry[1], entry[1]));
    }
  });
  department.value = preset[0];
  if (department.selectedIndex < 0) department.selectedIndex = 0;
  department.addEventListener('change', function () { fillDoctors(''); });
  doctor.addEventListener('change', loadShifts);
  date.addEventListener('input', loadShifts);
  date.addEventListener('change', loadShifts);
  form.addEventListener('submit', function (event) {
    if (loading || submitting || !shift.value) { event.preventDefault(); return; }
    submitting = true;
    updateSubmit();
  });
  window.addEventListener('pageshow', function (event) {
    if (event.persisted) {
      submitting = false;
      loadShifts();
    }
  });
  fillDoctors(preset[1]);
})();
