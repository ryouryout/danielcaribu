'use strict';

import { la } from './utils.js';
import { Storage } from './storage.js';

const available_langs = {
  "jp_jp": { "name": "日本語", "file": "jp_jp.json", "direction": "ltr"}
};

const DEFAULT_LANGUAGE = "jp_jp";

// Translation state - will be imported from core.js app object
let translationState = null;
let welcomeModal = null;
let handleLanguageChange = null;

export async function lang_init(appState, handleLanguageChangeCb, welcomeModalCb) {
  translationState = appState;
  handleLanguageChange = handleLanguageChangeCb;
  welcomeModal = welcomeModalCb;
  
  let id_iter = 0;
  const items = document.getElementsByClassName('ds-i18n');
  for(let item of items) {
    if (item.id.length == 0) {
      item.id = `ds-i18n-${id_iter++}`;
    }
    
    translationState.lang_orig_text[item.id] = $(item).html();
  }
  translationState.lang_orig_text[".title"] = document.title;
  
  const langs = Object.keys(available_langs);
  if (document.getElementById("availLangs")) {
    const olangs = [
      '<li><a class="dropdown-item" href="#" onclick="lang_set(\'en_us\');">English</a></li>',
      ...langs.map(lang => {
        const name = available_langs[lang]["name"];
        return `<li><a class="dropdown-item" href="#" onclick="lang_set('${lang}');">${name}</a></li>`;
      })
    ].join('');
    $("#availLangs").html(olangs);
  }

  const force_lang = Storage.getString("force_lang");
  const requestedLang = force_lang ?? DEFAULT_LANGUAGE;
  const targetLang = requestedLang === "en_us" || available_langs[requestedLang]
    ? requestedLang
    : DEFAULT_LANGUAGE;

  if (targetLang !== "en_us") {
    const { file, direction } = available_langs[targetLang];
    la("lang_init", {"l": targetLang});
    try {
      await lang_translate(file, targetLang, direction);
    } catch (error) {
      console.error("Failed to load initial language:", error);
    }
  } else {
    $("#curLang").html("English");
  }
}

async function lang_set(lang, skip_modal=false) {
  la("lang_set", { l: lang });
  
  lang_reset_page();
  if(lang != "en_us") {
    const { file, direction } = available_langs[lang];
    await lang_translate(file, lang, direction);
  }
  
  await handleLanguageChange(lang);
  Storage.setString("force_lang", lang);
  if(!skip_modal && welcomeModal) {
    Storage.setString("welcome_accepted", "0");
    welcomeModal();
  }
}

function lang_reset_page() {
  lang_set_direction("ltr", "en_us");

  // Reset translation state to disable translations
  translationState.lang_cur = {};
  translationState.lang_disabled = true;

  const { lang_orig_text } = translationState;
  const items = document.getElementsByClassName('ds-i18n');
  for(let item of items) {
    $(item).html(lang_orig_text[item.id]);
  };
  $("#authorMsg").html("");
  $("#curLang").html("English");
  document.title = lang_orig_text[".title"];
}

function lang_set_direction(new_direction, lang_name) {
  const lang_prefix = lang_name.split("_")[0]
  $("html").attr("lang", lang_prefix);

  if(new_direction == translationState.lang_cur_direction)
    return;

  if(new_direction == "rtl") {
    $('#bootstrap-css').attr('integrity', 'sha384-dpuaG1suU0eT09tx5plTaGMLBsfDLzUCCUXOY2j/LSvXYuG6Bqs43ALlhIqAJVRb');
    $('#bootstrap-css').attr('href', 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css');
  } else {
    $('#bootstrap-css').attr('integrity', 'sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH');
    $('#bootstrap-css').attr('href', 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css');
  }
  $("html").attr("dir", new_direction);
  translationState.lang_cur_direction = new_direction;
}

function loadTranslationFile(path, optional = false) {
  return new Promise((resolve, reject) => {
    $.getJSON(path)
      .done(resolve)
      .fail((jqxhr, textStatus, error) => {
        if (optional) {
          resolve({});
          return;
        }
        console.error("Failed to load translation file:", path, error);
        reject(error);
      });
  });
}

export function l(text) {
  if(!translationState || translationState.lang_disabled)
    return text;

  const [out] = translationState.lang_cur[text] || [];
  if(out) return out;
  
  console.log(`Missing translation for "${text}"`);
  return text;
}

async function lang_translate(target_file, target_lang, target_direction) {
  const baseData = await loadTranslationFile("lang/" + target_file);
  const overrideData = target_lang === DEFAULT_LANGUAGE
    ? await loadTranslationFile("lang/jp_jp_override.json", true)
    : {};
  const data = { ...baseData, ...overrideData };
  const { lang_orig_text, lang_cur } = translationState;

  lang_set_direction(target_direction, target_lang);

  $.each(data, function(key, val) {
    lang_cur[key] = [val];
  });

  if(Object.keys(lang_cur).length > 0) {
    translationState.lang_disabled = false;
  }

  const items = document.getElementsByClassName('ds-i18n');
  for(let item of items) {
    const originalText = lang_orig_text[item.id];
    const [translatedText] = lang_cur[originalText] || [];
    if (translatedText) {
      $(item).html(translatedText);
    } else {
      console.log(`Cannot find mapping for "${originalText}"`);
      $(item).html(originalText);
    }
  }

  const old_title = lang_orig_text[".title"];
  const [translatedTitle] = lang_cur[old_title] || [];
  document.title = translatedTitle || old_title;
  if(lang_cur[".authorMsg"]) {
    $("#authorMsg").html(lang_cur[".authorMsg"][0]);
  }
  $("#curLang").html(target_lang === "en_us" ? "English" : available_langs[target_lang]["name"]);
}

// Make lang_set available globally for onclick handlers in HTML
window.lang_set = lang_set;
