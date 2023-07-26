DESCRIPTION = "Linux kernel for theIMX IOT board"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"
CUSTOMIZEFILESDIR := "${THISDIR}/${PN}-${PV}"

do_copy_defconfig_append() {
	bbplain "linux-imx_5.4.bbappend will copy defconfig files to ${S}/arch/arm64/configs"
	bbplain "linux-imx_5.4.bbappend will copy dts files to ${S}/arch/arm64/boot/dts/freescale"
	cp ${CUSTOMIZEFILESDIR}/imx8mp-*.dts* ${S}/arch/arm64/boot/dts/freescale
}

do_srcexport() {
	cd ${STAGING_KERNEL_DIR} && cp ${STAGING_KERNEL_BUILDDIR}/.config .config && tar cvzf ${DEPLOY_DIR}/linux-imx-5.4.tar.gz --exclude=oe-* * .config && rm .config
}
addtask srcexport after patch
do_srcexport[nostamp] = "1"

addtask showvars
do_showvars[nostamp] = "1"
python do_showvars(){
    # emit only the metadata that are variables and not functions
    isfunc = lambda key: bool(d.getVarFlag(key, 'func'))
    vars = sorted((key for key in bb.data.keys(d) \
        if not key.startswith('__')))
    for var in vars:
        if not isfunc(var):
            try:
                val = d.getVar(var, True)
            except Exception as exc:
                bb.plain('Expansion of %s threw %s: %s' % \
                    (var, exc.__class__.__name__, str(exc)))
            bb.plain('%s="%s"' % (var, val))
}

do_compile_dtb() {
    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS MACHINE
    cc_extra=$(get_cc_option)
    if [ -n "${KERNEL_DTC_FLAGS}" ]; then
        export DTC_FLAGS="${KERNEL_DTC_FLAGS}"
    fi
    for dtbf in ${KERNEL_DEVICETREE}; do
        dtb=`normalize_dtb "$dtbf"`
        dtb_ext=${dtb##*.}
        dtb_base_name=`basename $dtb .$dtb_ext`
        dtb_path=`get_real_dtb_path_in_kernel "$dtb"`
        oe_runmake -C ${B} ${dtb} CC="${KERNEL_CC} $cc_extra " LD="${KERNEL_LD}" ${KERNEL_EXTRA_ARGS}
    done
    for dtbf in ${EXTRA_DTBS}; do
        dtb="renesas/${dtbf}"
        dtb_ext=${dtb##*.}
        dtb_base_name=`basename $dtb .$dtb_ext`
        dtb_path=`get_real_dtb_path_in_kernel "$dtb"`
        oe_runmake -C ${B} ${dtb} CC="${KERNEL_CC} $cc_extra " LD="${KERNEL_LD}" ${KERNEL_EXTRA_ARGS}
    done
}

do_deploy_dtb() {
    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS MACHINE
    cc_extra=$(get_cc_option)
    if [ -n "${KERNEL_DTC_FLAGS}" ]; then
        export DTC_FLAGS="${KERNEL_DTC_FLAGS}"
    fi
    for dtbf in ${KERNEL_DEVICETREE}; do
        dtb=`normalize_dtb "$dtbf"`
        dtb_ext=${dtb##*.}
        dtb_base_name=`basename $dtb .$dtb_ext`
        dtb_path=`get_real_dtb_path_in_kernel "$dtb"`
        install -m 0644 $dtb_path ${DEPLOY_DIR_IMAGE}/$dtb_base_name.$dtb_ext
    done
    for dtbf in ${EXTRA_DTBS}; do
        dtb="renesas/${dtbf}"
        dtb_ext=${dtb##*.}
        dtb_base_name=`basename $dtb .$dtb_ext`
        dtb_path=`get_real_dtb_path_in_kernel "$dtb"`
        install -m 0644 $dtb_path ${DEPLOY_DIR_IMAGE}/$dtb_base_name.$dtb_ext
    done
}

do_compile_dtb[nostamp] = "1"
addtask do_compile_dtb
addtask do_deploy_dtb after do_compile_dtb
addtask do_build_dtb after do_deploy_dtb
do_build_dtb () {
        :
}
do_build_dtb[nostamp] = "1"

