$(document).ready(function() {
  if (!CKEDITOR) return;

  const config = {
    resize_enabled: true,
    // Prevents showing a prompt to upgrade
    // ckeditor to a newer, comercial licenced
    // version
    versionCheck: false,
  };

  $('textarea.editor').each(function(){
    CKEDITOR.replace(this.id, {
      toolbar:
        [
          ['Source','-','Preview'],
          ['Cut','Copy','Paste','PasteText','PasteFromWord','SpellChecker','Scayt'],
          ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
          ['Maximize', 'ShowBlocks'],
          '/',
          ['Bold','Italic','Underline'],
          ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
          ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
          ['Link','Unlink'],
          ['Image','Table','HorizontalRule','SpecialChar'],
          ['TextColor']
        ],
      ...config
    });
  });

  $('textarea.editor__simple').each(function(){
    CKEDITOR.replace(this.id, {
      toolbar:
        [
          ['Bold','Italic','Underline'],
          ['Link','Unlink'],
          ['Cut','Copy','Paste','PasteText','PasteFromWord',],
          ['Undo','Redo','-','SelectAll','RemoveFormat'],
          ['ShowBlocks'],
        ],
      ...config
    });
  });

});
