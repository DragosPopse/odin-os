package odin_os_build // make this as unique as you can as a good practice

import "core:build"
import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:c/libc"

Mode :: enum {
	Debug,
	Release,
}

DEFAULT_PLATFORM :: build.Platform{
	os = .Freestanding,
	arch = .amd64, // sysv?
	abi = .SysV,
}

Target :: struct {
	using target: build.Target,
	mode: Mode,
}

target_debug := Target{
	target = {
		name = "deb",
		platform = DEFAULT_PLATFORM,
	},
	mode = .Debug,
}

target_release := Target{
	target = {
		name = "rel",
		platform = DEFAULT_PLATFORM,
	},
	mode = .Release,
}

project: build.Project

export_odin_root :: proc(config: build.Config) -> int {
	os.set_env("ODIN_ROOT", "kernel")
	return 0
}

config_target :: proc(project: ^build.Project, target: ^build.Target, settings: build.Settings) -> (config: build.Config) {
	target := cast(^Target)target
	config.platform = target.platform
	config.out_file = "kernel"
	config.out_dir = "bin"
	config.build_mode = .OBJ
	config.src_path = "kernel"
	if target.mode == .Debug do config.flags += {.Debug}
	config.flags += {
		.No_CRT,
		.No_Thread_Local,
		.No_Entry_Point,
		.Disable_Red_Zone,
		.Default_To_Nil_Allocator,
		.Foreign_Error_Procedures,
		.Disallow_Do,
		.No_Threaded_Checker,
		.No_RTTI,
	}
	config.vet += build.DEFAULT_VET
	config.reloc = .PIC // To implement
	config.collections["kernel"] = "kernel"
	//config.max_error_count = 5 // To Add

	build.add_pre_build_command(&config, "export ODIN_ROOT", export_odin_root)
	return config
}

// This can be placed inside main, but we'll consider this approach good practice
// The general reason for this is that it allows including this build system into others
@init
_ :: proc() {
	context = build.default_context()
	project.name = "Odin Toy OS"
	build.add_target(&project, &target_debug)
	project.configure_target_proc = config_target  // This needs to be checked for. It segfaults if not placed
}

main :: proc() {
	context = build.default_context()
	settings: build.Settings
	build.settings_init_from_args(&settings, os.args, {})
	settings.default_target_name = "deb"
	build.run(&project, settings)
}
