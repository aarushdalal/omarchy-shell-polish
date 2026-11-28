# MultiEnv Monolith Plymouth Theme Script — Theme-Adapted Frosted Glass

Window.SetBackgroundTopColor({{BG_R}}, {{BG_G}}, {{BG_B}});
Window.SetBackgroundBottomColor({{BG_R}}, {{BG_G}}, {{BG_B}});

# Fullscreen Blurred Wallpaper Background
bg.image = Image("background.png");
if (bg.image) {
  bg.sprite = Sprite();
  bg.sprite.SetOpacity(1);
}

# Brand Logo (Centered during Boot/Loading/Shutdown, Floating above Card during Unlock)
logo.image = Image("logo.png");
if (logo.image) {
  logo.sprite = Sprite(logo.image);
  logo.sprite.SetOpacity(1);
}

# Frosted Glass Monolith Card (contains 24px ambient shadow padding around 420x276 glass body)
card.image = Image("card.png");
if (card.image) {
  card.sprite = Sprite(card.image);
  card.sprite.SetOpacity(0);
}

# Dialogue Elements
lock.image = Image("lock.png");
entry.image = Image("entry.png");
bullet.image = Image("bullet.png");

entry.sprite = Sprite(entry.image);
entry.sprite.SetOpacity(0);

lock.width = 18;
lock.height = 18;
lock.sprite = Sprite(lock.image.Scale(lock.width, lock.height));
lock.sprite.SetOpacity(0);

bullet.sprites = [];

# Typography Text Sprites (Theme-Adapted RGB)
title.image = Image.Text("Encrypted Storage", {{FG_R}}, {{FG_G}}, {{FG_B}}, 1, "Noto Sans Bold 13");
title.sprite = Sprite(title.image);
title.sprite.SetOpacity(0);

subtitle.image = Image.Text("Enter passphrase to unlock root partition", {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 1, "Noto Sans 10");
subtitle.sprite = Sprite(subtitle.image);
subtitle.sprite.SetOpacity(0);

device.image = Image.Text("{{CRYPT_LABEL}}", {{MUT_R}}, {{MUT_G}}, {{MUT_B}}, 1, "Noto Sans 9");
device.sprite = Sprite(device.image);
device.sprite.SetOpacity(0);

footer.image = Image.Text("ENTER: Decrypt & Boot   ESC: Clear", {{MUT_R}}, {{MUT_G}}, {{MUT_B}}, 1, "Noto Sans 9");
footer.sprite = Sprite(footer.image);
footer.sprite.SetOpacity(0);

# Splash / Loading / Shutdown Status Captions
brand_wordmark.image = Image.Text("{{BRAND_WORDMARK}}", {{FG_R}}, {{FG_G}}, {{FG_B}}, 0.92, "Noto Sans Medium 11");
brand_wordmark.sprite = Sprite(brand_wordmark.image);
brand_wordmark.sprite.SetOpacity(0);

status_boot.image = Image.Text("Initializing encrypted workspace…", {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 0.85, "Noto Sans 10");
status_loading.image = Image.Text("Unlocking system & starting services…", {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 0.90, "Noto Sans 10");
status_shutdown.image = Image.Text("Shutting down safely…", {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 0.90, "Noto Sans 10");
status_reboot.image = Image.Text("Restarting system…", {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 0.90, "Noto Sans 10");
status_suspend.image = Image.Text("Suspending session…", {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 0.90, "Noto Sans 10");

status_caption.sprite = Sprite(status_boot.image);
status_caption.sprite.SetOpacity(0);
global.current_status_width = status_boot.image.GetWidth();

# Progress Bar & Indeterminate Pulse Elements
progress_box.image = Image("progress_box.png");
progress_box.sprite = Sprite(progress_box.image);
progress_box.sprite.SetOpacity(0);

progress_bar.original_image = Image("progress_bar.png");
progress_bar.sprite = Sprite();
progress_bar.image = progress_bar.original_image.Scale(1, progress_bar.original_image.GetHeight());
progress_bar.sprite.SetOpacity(0);

pulse_pill.image = Image("pulse_pill.png");
if (pulse_pill.image) {
  pulse_pill.sprite = Sprite(pulse_pill.image);
  pulse_pill.sprite.SetOpacity(0);
}

global.animation_frame = 0;
global.fake_progress = 0.0;
global.real_progress = 0.0;
global.fake_progress_active = 0;
global.fake_progress_start_time = 0.0;
global.fake_progress_limit = 0.72;
global.fake_progress_duration = 15.0;
global.password_shown = 0;
global.in_password_mode = 0;
global.pulse_active = 0;
global.max_progress = 0.0;

global.layout_width = 0;
global.layout_height = 0;

fun position_bullet(index) {
  bullet.sprites[index].SetPosition(entry.x + 42 + index * 12, entry.y + entry.image.GetHeight() / 2 - 4, 10002);
}

fun position_status_caption() {
  if (global.layout_width > 0) {
    status_caption.sprite.SetPosition(
      global.layout_width / 2 - global.current_status_width / 2,
      global.splash_status_y,
      1000
    );
  }
}

fun set_status_image(img) {
  status_caption.sprite.SetImage(img);
  global.current_status_width = img.GetWidth();
  position_status_caption();
}

fun show_splash_chrome(show_determinate, show_pulse) {
  if (logo.sprite) {
    logo.sprite.SetPosition(global.splash_logo_x, global.splash_logo_y, 500);
    logo.sprite.SetOpacity(1);
  }
  brand_wordmark.sprite.SetOpacity(1);
  status_caption.sprite.SetOpacity(1);
  progress_box.sprite.SetOpacity(1);

  if (show_determinate == 1) {
    progress_bar.sprite.SetOpacity(1);
  } else {
    progress_bar.sprite.SetOpacity(0);
  }

  global.pulse_active = show_pulse;
  if (pulse_pill.sprite) {
    if (show_pulse == 1) {
      pulse_pill.sprite.SetOpacity(1);
    } else {
      pulse_pill.sprite.SetOpacity(0);
    }
  }
}

fun hide_splash_chrome() {
  brand_wordmark.sprite.SetOpacity(0);
  status_caption.sprite.SetOpacity(0);
  progress_box.sprite.SetOpacity(0);
  progress_bar.sprite.SetOpacity(0);
  global.pulse_active = 0;
  if (pulse_pill.sprite) pulse_pill.sprite.SetOpacity(0);
}

fun show_password_dialog() {
  global.in_password_mode = 1;
  hide_splash_chrome();

  if (logo.sprite) {
    logo.sprite.SetPosition(global.unlock_logo_x, global.unlock_logo_y, 500);
    logo.sprite.SetOpacity(1);
  }
  if (card.sprite) card.sprite.SetOpacity(1);
  title.sprite.SetOpacity(1);
  subtitle.sprite.SetOpacity(1);
  device.sprite.SetOpacity(1);
  footer.sprite.SetOpacity(1);
  lock.sprite.SetOpacity(1);
  entry.sprite.SetOpacity(1);
}

fun hide_password_dialog() {
  global.in_password_mode = 0;
  if (card.sprite) card.sprite.SetOpacity(0);
  title.sprite.SetOpacity(0);
  subtitle.sprite.SetOpacity(0);
  device.sprite.SetOpacity(0);
  footer.sprite.SetOpacity(0);
  lock.sprite.SetOpacity(0);
  entry.sprite.SetOpacity(0);

  for (index = 0; bullet.sprites[index]; index++) {
    bullet.sprites[index].SetOpacity(0);
  }
}

fun update_progress_bar(progress) {
  if (progress > global.max_progress) {
    global.max_progress = progress;
    width = Math.Int(progress_bar.original_image.GetWidth() * progress);
    if (width < 1) width = 1;
    progress_bar.image = progress_bar.original_image.Scale(width, progress_bar.original_image.GetHeight());
    progress_bar.sprite.SetImage(progress_bar.image);
  }
}

fun start_fake_progress() {
  global.fake_progress_active = 1;
  global.animation_frame = 0;
  global.max_progress = 0.0;
  global.fake_progress = 0.0;
  global.fake_progress_start_time = 0.0;
}

fun stop_fake_progress() {
  global.fake_progress_active = 0;
}

fun display_normal_callback() {
  hide_password_dialog();
  mode = Plymouth.GetMode();

  if (mode == "shutdown") {
    stop_fake_progress();
    set_status_image(status_shutdown.image);
    show_splash_chrome(0, 1);
  } else if (mode == "reboot") {
    stop_fake_progress();
    set_status_image(status_reboot.image);
    show_splash_chrome(0, 1);
  } else if (mode == "suspend") {
    stop_fake_progress();
    set_status_image(status_suspend.image);
    show_splash_chrome(0, 1);
  } else if ((mode == "boot" || mode == "resume") && global.password_shown == 1) {
    set_status_image(status_loading.image);
    show_splash_chrome(1, 0);
    start_fake_progress();
  } else {
    stop_fake_progress();
    set_status_image(status_boot.image);
    show_splash_chrome(0, 1);
  }
}

fun display_password_callback(prompt, bullets) {
  global.password_shown = 1;
  stop_fake_progress();
  show_password_dialog();

  for (index = 0; bullet.sprites[index]; index++) {
    bullet.sprites[index].SetOpacity(0);
  }

  max_bullets = 21;
  bullets_to_show = bullets;
  if (bullets_to_show > max_bullets) bullets_to_show = max_bullets;

  for (index = 0; index < bullets_to_show; index++) {
    if (!bullet.sprites[index]) {
      bullet.sprites[index] = Sprite(bullet.image.Scale(8, 8));
      position_bullet(index);
    }
    bullet.sprites[index].SetOpacity(1);
  }
}

Plymouth.SetDisplayNormalFunction(display_normal_callback);
Plymouth.SetDisplayPasswordFunction(display_password_callback);

fun progress_callback(duration, progress) {
  if (global.fake_progress_start_time == 0.0) {
    global.fake_progress_start_time = duration;
  }
  global.real_progress = progress;
  if (duration > global.fake_progress_start_time && progress > global.fake_progress) {
    stop_fake_progress();
    update_progress_bar(progress);
  }
}

Plymouth.SetBootProgressFunction(progress_callback);

fun refresh_callback() {
  if (Window.GetWidth() != global.layout_width || Window.GetHeight() != global.layout_height) {
    layout();
  }
  global.animation_frame++;

  if (logo.sprite && global.in_password_mode == 0) {
    breathe = 0.88 + 0.12 * (0.5 + 0.5 * Math.Sin(global.animation_frame * 0.06));
    logo.sprite.SetOpacity(breathe);
  }

  if (global.pulse_active == 1 && pulse_pill.sprite) {
    travel = progress_box.image.GetWidth() - pulse_pill.image.GetWidth();
    phase = 0.5 - 0.5 * Math.Cos(global.animation_frame * 0.055);
    pulse_pill.sprite.SetPosition(progress_box.x + travel * phase, progress_box.y, 1002);
  }

  if (global.fake_progress_active == 1) {
    elapsed_time = global.animation_frame / 50.0;
    time_ratio = elapsed_time / global.fake_progress_duration;
    if (time_ratio > 1.0) time_ratio = 1.0;
    eased_ratio = 1 - ((1 - time_ratio) * (1 - time_ratio));
    global.fake_progress = eased_ratio * global.fake_progress_limit;
    update_progress_bar(global.fake_progress);
  }
}

Plymouth.SetRefreshFunction(refresh_callback);

fun layout() {
  global.layout_width = Window.GetWidth();
  global.layout_height = Window.GetHeight();

  if (bg.sprite && bg.image) {
    bg.sprite.SetImage(bg.image.Scale(global.layout_width, global.layout_height));
    bg.sprite.SetPosition(0, 0, 0);
  }

  card_shadow_pad = 24;
  inner_card_h = 276;
  logo_w = 96;
  logo_h = 96;
  if (logo.image) {
    logo_w = logo.image.GetWidth();
    logo_h = logo.image.GetHeight();
  }
  logo_card_gap = 24;

  unlock_group_h = logo_h + logo_card_gap + inner_card_h;
  unlock_group_top = global.layout_height / 2 - unlock_group_h / 2;

  global.unlock_logo_x = global.layout_width / 2 - logo_w / 2;
  global.unlock_logo_y = unlock_group_top;

  card_inner_top = unlock_group_top + logo_h + logo_card_gap;
  card_x = global.layout_width / 2 - card.image.GetWidth() / 2;
  card_y = card_inner_top - card_shadow_pad;
  if (card.sprite) {
    card.sprite.SetPosition(card_x, card_y, 100);
  }

  title.sprite.SetPosition(global.layout_width / 2 - title.image.GetWidth() / 2, card_inner_top + 42, 10001);
  subtitle.sprite.SetPosition(global.layout_width / 2 - subtitle.image.GetWidth() / 2, card_inner_top + 74, 10001);

  entry.x = global.layout_width / 2 - entry.image.GetWidth() / 2;
  entry.y = card_inner_top + 118;
  entry.sprite.SetPosition(entry.x, entry.y, 10001);

  lock.x = entry.x + 15;
  lock.y = entry.y + entry.image.GetHeight() / 2 - lock.height / 2;
  lock.sprite.SetPosition(lock.x, lock.y, 10002);

  for (index = 0; bullet.sprites[index]; index++) {
    position_bullet(index);
  }

  device.sprite.SetPosition(global.layout_width / 2 - device.image.GetWidth() / 2, entry.y + entry.image.GetHeight() + 26, 10001);
  footer.sprite.SetPosition(global.layout_width / 2 - footer.image.GetWidth() / 2, global.layout_height - 36, 10001);

  splash_total_h = logo_h + 22 + brand_wordmark.image.GetHeight() + 18 + progress_box.image.GetHeight() + 16 + status_boot.image.GetHeight();
  splash_top = global.layout_height / 2 - splash_total_h / 2;

  global.splash_logo_x = global.layout_width / 2 - logo_w / 2;
  global.splash_logo_y = splash_top;

  brand_wordmark.sprite.SetPosition(
    global.layout_width / 2 - brand_wordmark.image.GetWidth() / 2,
    splash_top + logo_h + 22,
    1000
  );

  progress_box.x = global.layout_width / 2 - progress_box.image.GetWidth() / 2;
  progress_box.y = splash_top + logo_h + 22 + brand_wordmark.image.GetHeight() + 18;
  progress_box.sprite.SetPosition(progress_box.x, progress_box.y, 1000);

  progress_bar.x = global.layout_width / 2 - progress_bar.original_image.GetWidth() / 2;
  progress_bar.y = progress_box.y + (progress_box.image.GetHeight() - progress_bar.original_image.GetHeight()) / 2;
  progress_bar.sprite.SetPosition(progress_bar.x, progress_bar.y, 1001);

  if (pulse_pill.sprite) {
    pulse_pill.sprite.SetPosition(progress_box.x, progress_box.y, 1002);
  }

  global.splash_status_y = progress_box.y + progress_box.image.GetHeight() + 16;
  position_status_caption();

  if (logo.sprite) {
    if (global.in_password_mode == 1) {
      logo.sprite.SetPosition(global.unlock_logo_x, global.unlock_logo_y, 500);
    } else {
      logo.sprite.SetPosition(global.splash_logo_x, global.splash_logo_y, 500);
    }
  }
}

layout();
display_normal_callback();

message_sprite = Sprite();

fun display_message_callback(text) {
  message = Image.Text(text, {{SEC_R}}, {{SEC_G}}, {{SEC_B}}, 1, "Noto Sans 10");
  message_sprite.SetImage(message);
  if (global.in_password_mode == 1) {
    message_sprite.SetPosition(global.layout_width / 2 - message.GetWidth() / 2, global.layout_height - 68, 10003);
  } else {
    message_sprite.SetPosition(global.layout_width / 2 - message.GetWidth() / 2, global.splash_status_y + 28, 10003);
  }
  message_sprite.SetOpacity(1);
}

fun hide_message_callback(text) {
  message_sprite.SetOpacity(0);
}

Plymouth.SetDisplayMessageFunction(display_message_callback);
Plymouth.SetHideMessageFunction(hide_message_callback);
