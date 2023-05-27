#include "kernel.h"
#include <dlfcn.h>
#include <sys/sysctl.h>

//set offset
#define kCFCoreFoundationVersionNumber_iOS_15_0 (1854)
#define kCFCoreFoundationVersionNumber_iOS_15_2 (1856.105)

uint32_t off_p_pid = 0;
uint32_t off_p_pfd = 0;
uint32_t off_fd_ofiles = 0;
uint32_t off_fp_fglob = 0;
uint32_t off_fg_data = 0;
uint32_t off_vnode_iocount = 0;
uint32_t off_vnode_usecount = 0;
uint32_t off_vnode_vflags = 0;

int offset_init() {
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_15_2) {
		// ios 15.2+
		printf("iOS 15.2+ offset selected!!!\n");
		off_p_pid = 0x68; //proc_pid v
        off_p_pfd = 0x100;  //
        off_fd_ofiles = 0x0; //?
        off_fp_fglob = 0x10;
        off_fg_data = 0x38; //_fg_get_vnode + 10, LDR X0, [X0,#0x38]
        off_vnode_iocount = 0x64; //vnode_iocount v
        off_vnode_usecount = 0x60; //vnode_usecount v
        off_vnode_vflags = 0x54; //_vnode_isvroot, _vnode_issystem, _vnode_isswap... LDR W8, [X0,#0x54] v
		off_p_pfd = 0xf8;
		return 0;
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_15_0) {
        // ios 15.0-15.1.1
        printf("iOS 15.0-15.1.1 offset selected!!!\n");
        off_p_pid = 0x68; //proc_pid v
        off_p_pfd = 0x100;  //
        off_fd_ofiles = 0x0; //?
        off_fp_fglob = 0x10;
        off_fg_data = 0x38; //_fg_get_vnode + 10, LDR X0, [X0,#0x38]
        off_vnode_iocount = 0x64; //vnode_iocount v
        off_vnode_usecount = 0x60; //vnode_usecount v
        off_vnode_vflags = 0x54; //_vnode_isvroot, _vnode_issystem, _vnode_isswap... LDR W8, [X0,#0x54] v

        return 0;
    }

	return -1;
}

bool isArm64e(void) {
	cpu_subtype_t subtype;
    size_t cpusz = sizeof(cpu_subtype_t);
    sysctlbyname("hw.cpusubtype", &subtype, &cpusz, NULL, 0);
	return (subtype == 2/*CPU_SUBTYPE_ARM64E*/);
}

void kwrite64(uint64_t va, uint64_t v) {
	if(isArm64e()) {
		void *libjb = dlopen("/var/jb/basebin/libjailbreak.dylib", RTLD_NOW);
		// printf("libjb: %p\n", libjb);
		void *libjb_kwrite64 = dlsym(libjb, "kwrite64");
		int (*kwrite64_)(uint64_t va, uint64_t v) = libjb_kwrite64;
		kwrite64_(va, v);
		dlclose(libjb);
	} else {
		kernel_write64(va, v);
	}
}

void kwrite32(uint64_t va, uint32_t v) {
	if(isArm64e()) {
		void *libjb = dlopen("/var/jb/basebin/libjailbreak.dylib", RTLD_NOW);
		// printf("libjb: %p\n", libjb);
		void *libjb_kwrite32 = dlsym(libjb, "kwrite32");
		int (*kwrite32_)(uint64_t va, uint32_t v) = libjb_kwrite32;
		kwrite32_(va, v);
		dlclose(libjb);
	} else {
		kernel_write32(va, v);
	}
}

//get vnode
uint64_t get_vnode_with_file_index(int file_index, uint64_t proc) {

	uint64_t filedesc = kernel_read64(proc + off_p_pfd);
	uint64_t openedfile = kernel_read64(filedesc + (8 * file_index));

	uint64_t fileglob = kernel_read64(openedfile + off_fp_fglob);
	uint64_t vnode = kernel_read64(fileglob + off_fg_data);

	uint32_t usecount = kernel_read32(vnode + off_vnode_usecount);
	uint32_t iocount = kernel_read32(vnode + off_vnode_iocount);

	kwrite32(vnode + off_vnode_usecount, usecount + 1);
	kwrite32(vnode + off_vnode_iocount, iocount + 1);

	return vnode;
}

//hide and show file using vnode
#define VISSHADOW 0x008000
void hide_path(uint64_t vnode){
	uint32_t v_flags = kernel_read32(vnode + off_vnode_vflags);
	kwrite32(vnode + off_vnode_vflags, (v_flags | VISSHADOW));
}

void show_path(uint64_t vnode){
	uint32_t v_flags = kernel_read32(vnode + off_vnode_vflags);
	kwrite32(vnode + off_vnode_vflags, (v_flags &= ~VISSHADOW));
}

int init_kernel() {

  	printf("======= init_kernel =======\n");

  	if(dimentio_init(0, NULL, NULL) != KERN_SUCCESS) {
    	printf("failed dimentio_init!\n");
		return 1;
  	}

	if(kbase == 0) {
		printf("failed get_kbase\n");
		return 1;
	}

	kern_return_t err = offset_init();
	if (err) {
		printf("offset init failed: %d\n", err);
		return 1;
	}
	return 0;
}
