###########################################################
#
# classes/tsmeta.bbclass - Metadata Collection
#
# Copyright (C) 2019 Timesys Corporation
#
#
# This source is released under the MIT License.
#
###########################################################

tsmeta_dirname = "tsmeta"
tsmeta_dir = "${TMPDIR}/${tsmeta_dirname}"

tsmeta_cve_dir = "${tsmeta_dir}/cve"
tsmeta_image_dir = "${tsmeta_dir}/image"
tsmeta_packageconfig_dir = "${tsmeta_dir}/packageconfig"
tsmeta_pkg_dir = "${tsmeta_dir}/pkg"
tsmeta_pn_dir = "${tsmeta_dir}/pn"
tsmeta_recipe_dir = "${tsmeta_dir}/recipe"
tsmeta_src_dir = "${tsmeta_dir}/src"

tsmeta_distro_dir = "${tsmeta_dir}/distro"
tsmeta_features_dir = "${tsmeta_dir}/features"
tsmeta_image_dir = "${tsmeta_dir}/image"
tsmeta_layers_dir = "${tsmeta_dir}/layers"
tsmeta_machine_dir = "${tsmeta_dir}/machine"
tsmeta_preferred_dir = "${tsmeta_dir}/preferred"

tsmeta_lvars_pkg = " \
    ALTERNATIVE     \
    RCONFLICTS      \
    RDEPENDS        \
    RPROVIDES       \
    RRECOMMENDS     \
    RREPLACES       \
    RSUGGESTS       \
"

tsmeta_vars_pkg = " \
    SECTION         \
    PACKAGE_ARCH    \
    PKG             \
"

tsmeta_vars_pn = "  \
    BP              \
    BPN             \
    EXTENDPKGV      \
    PF              \
    PKGR            \
    PKGV            \
    PN              \
    PV              \
"

tsmeta_lvars_pn = " \
    DEPENDS \
    IMAGE_INSTALL \
    PACKAGECONFIG \
    PACKAGECONFIG_CONFARGS  \
    PACKAGES \
    PACKAGES_DYNAMIC\
    PROVIDES \
"


tsmeta_vars_recipe = "\
    FILE                    \
    FILE_DIRNAME            \
"

tsmeta_lvars_recipe = "\
    FILESEXTRAPATHS         \
"

tsmeta_lvars_src = "\
    SRC_URI                 \
"

tsmeta_vars_src = "\
    BRANCH                  \
    CVE_PRODUCT             \
    CVE_VERSION             \
    SRCBRANCH               \
    SRCREV                  \
"


def tsmeta_get_type_dir(d, tsm_type):
    key = "tsmeta_" + tsm_type.lower() + "_dir"
    return d.getVar(key)

def tsmeta_get_type_path(d, tsm_type, var_name):
    return os.path.join(
        tsmeta_get_type_dir(d, tsm_type),
        var_name + ".json")

def tsmeta_get_type_glob(d, tsm_type):
    import glob
    ls_dict = dict()
    tsm_dir = tsmeta_get_type_dir(d, tsm_type)

    varfiles = glob.glob(os.path.join(tsm_dir, "*.json"))
    for vf in varfiles:
        basename = os.path.basename(vf)
        dict_name, ext = os.path.splitext(basename)
        ls_dict[dict_name] = vf
    return ls_dict

def tsmeta_read_json(d, trj_path):
    import json
    dict_in = dict()
    if os.path.exists(trj_path):
        with open(trj_path) as f:
            dict_in = json.load(f)
    return dict_in

def tsmeta_write_json(d, dict_out, twj_path):
    import json

    s = json.dumps(dict_out, indent=8, sort_keys=False)
    if twj_path:
        with open(twj_path, "w") as f:
            f.write(s)


def tsmeta_write_dictname(d, tsm_type, twd_name, twd_dict):
    import oe.packagedata
    import json

    tsm_dir = tsmeta_get_type_dir(d, tsm_type)
    bb.utils.mkdirhier(tsm_dir)

    outfile = tsmeta_get_type_path(d, tsm_type, twd_name)
    tsmeta_write_json(d, twd_dict, outfile)

def tsmeta_write_dict(d, tsm_type, twd_dict):
    twd_name = d.getVar('PN')
    tsmeta_write_dictname(d, tsm_type, twd_name, twd_dict)

def tsmeta_write_dictdir(d, tsm_type, twd_dict):
    for twd_name in twd_dict.keys():
        tsmeta_write_dictname(d, tsm_type, twd_name, twd_dict[twd_name])


TSMETA_DEBUG ?= "0"
tsmeta_debug_dir = "${tsmeta_dir}/debug"

def tsmeta_debug(d, dict_tag, dict_out):
    if bb.utils.to_boolean(d.getVar('TSMETA_DEBUG'), True):
        dict_name = ("%s-%s" % (d.getVar('PN'), dict_tag))
        tsmeta_write_dictname(d, 'debug', dict_name, dict_out)


def tsmeta_read_dictname(d, tsm_type, trd_name):
    infile = tsmeta_get_type_path(d, tsm_type, trd_name)
    return tsmeta_read_json(d, infile)

def tsmeta_read_dict(d, trd_type):
    trd_name = d.getVar('PN')
    return tsmeta_read_dictname(d, trd_type, trd_name)

def tsmeta_read_dictdir(d, tsm_type):
    trd_dict = dict()

    if not os.path.exists(tsmeta_get_type_dir(d,tsm_type)):
        bb.debug(2,"dict dir %s not found, generating.." % tsm_type)
        bb.build.exec_func("tsmeta_get_" + tsm_type, d)

    for dict_name, dict_path in sorted(tsmeta_get_type_glob(d, tsm_type).items()):
        trd_dict[dict_name] = tsmeta_read_json(d, dict_path)
    return trd_dict

def tsmeta_read_dictdir_files(d, trdf_type, trdf_list):
    indict = tsmeta_read_dictdir(d, trdf_type)
    dict_out = { key: indict.get(key, "") for key in trdf_list if key in indict.keys() }
    return dict_out


def tsmeta_read_dictname_vars(d, trdv_type, trdv_name, trdv_list):
    indict = tsmeta_read_dictname(d, trdv_type, trdv_name)
    dict_out = { key: indict.get(key, "") for key in trdv_list }
    return dict_out 


def tsmeta_read_dict_vars(d, trdv_type, trdv_list):
    pn = d.getVar('PN')
    return tsmeta_read_dictname_vars(d, trdv_type, pn, trdv_list)


def tsmeta_get_dict(d, tsm_type, dict_in):
    dict_out = dict()

    key =  tsm_type.upper()
    name = dict_in.get("name", d.getVar(key))
    varlist = dict_in.get("vars", [])

    if name:
        if len(varlist):
            dict_out = tsmeta_read_dictname_vars(d, tsm_type, name, varlist)
        else:
            dict_out = tsmeta_read_dictdir(d, tsm_type)
    return dict_out


def tsmeta_get_yocto_vars(d, varlist):
    dict_out = dict()
    for key in (d.getVar(varlist) or "").split():
        value = (d.getVar(key) or "")
        if value:
            dict_out[key.lower()] = value
    return dict_out

def read_var_list(d, tsm_type, dest_dict):
    varlist = "tsmeta_vars_" + tsm_type
    dest_dict.update(tsmeta_get_yocto_vars(d, varlist))

def read_lvar_list(d, tsm_type, dest_dict):
    varlist = "tsmeta_lvars_" + tsm_type

    dest_dict.update( 
            { 
                key.lower(): list((d.getVar(key) or "").split()) 
                    for key in (d.getVar(varlist) or "").split() 
            }
        )


def tsmeta_get_vars(d, tgv_type):
    dest_dict = dict()
    read_var_list(d, tgv_type, dest_dict)
    read_lvar_list(d, tgv_type, dest_dict)
    tsmeta_write_dict(d, tgv_type, dest_dict)


def tsmeta_get_pn(d):
    tsmeta_get_vars(d, "pn")

def tsmeta_get_recipe(d):
    import re

    tgv_type = "recipe"

    dest_dict = dict()
    read_var_list(d, tgv_type, dest_dict)
    read_lvar_list(d, tgv_type, dest_dict)

    ldict = tsmeta_read_dictdir(d, "layers")
    for lname, layer in ldict.items():
        if re.match(layer["pattern"], dest_dict["file"]):
            dest_dict["layer"] = layer["fs_name"]
            dest_dict["recipe"] = os.path.relpath(dest_dict["file"], layer["path"])
            break

    tsmeta_write_dict(d, tgv_type, dest_dict)

def tsmeta_get_src(d):

    tsm_type = "src"
    src_dict = dict()

    read_var_list(d, tsm_type, src_dict)
    read_lvar_list(d, tsm_type, src_dict)

    cve_p = src_dict.get("cve_product", d.getVar('BPN'))
    cve_v = src_dict.get("cve_version", d.getVar('PV'))

    chop_tags = [ '+git', '+AUTOINC' ]
    for tag in chop_tags:
        if tag in cve_v:
            cve_v = cve_v.split(tag)[0]
            break

    src_dict["cve_product"] = cve_p
    src_dict["cve_version"] = cve_v

    uri_dict = dict()

    def uri_add(u_type, u_path):
        if not u_type in uri_dict.keys():
            uri_dict[u_type] = list()
        uri_dict[u_type].append(u_path)

    def is_patch(u_spec):
        u_path = u_spec.split(";")[0]
        u_attrs = u_spec.split(";")[1:]

        if u_path.endswith(".patch") or u_path.endswith(".diff"):
            return True

        for u_a in u_attrs:
            if (u_a == "apply=yes") or (u_a.startswith("striplevel=")):
                return True

        return False

    for uri_desc in src_dict["src_uri"]:
        uri_uri = uri_desc.split(";")[0]

        (uri_type, uri_spec) = uri_desc.split("://", 1)
        uri_path = uri_spec.split(";")[0]

        if is_patch(uri_spec):
            uri_add("patches", uri_path)
        elif uri_type == "file":
            uri_add("other", uri_path)
        else:
            uri_add("base", uri_desc)

    src_dict["sources"] = uri_dict

    if src_dict["srcrev"] == "INVALID":
        src_dict.pop("srcrev")
    tsmeta_write_dict(d, tsm_type, src_dict)

def tsmeta_get_pkg(d):
    import oe.packagedata


    def get_var_list(varlist, pkg, d_sub):
        vdict = dict()
        for base_key in d.getVar(varlist).split():
            pkg_key = base_key + "_" + pkg
            dest_key = base_key.lower()

            if pkg_key in d_sub.keys():
                actual_key = pkg_key 
            elif base_key in d_sub.keys():
                actual_key = base_key
            else:
                continue

            value = d_sub[actual_key]
            if value != "" :
                vdict[dest_key] = value
        return vdict

    def read_extlvar_list(tsm_type, pkg, d_sub, dest_dict):
        varlist = "tsmeta_lvars_" + tsm_type
        vdict = get_var_list(varlist, pkg, d_sub)

        for key, value in vdict.items():
            dest_list = []
            for item in value.split():
                if item.startswith('(') or item.endswith(')') and len(dest_list):
                    dest_list[-1] += (" " + item)
                else:
                    dest_list.append(item)
            dest_dict[key] = list(dest_list)

    def read_extvar_list(tsm_type, pkg, d_sub, dest_dict):
        varlist = "tsmeta_vars_" + tsm_type
        dest_dict.update(get_var_list(varlist, pkg, d_sub))

    pd_dir = d.getVar('PKGDATA_DIR')

    pn_dict = dict()
    pn_name = d.getVar('PN')
    f_pn = os.path.join(pd_dir, pn_name)

    if not os.path.exists(f_pn):
        return

    with open(f_pn, 'r') as infile:
        for line in infile:
            pn_dict = { sp: dict() for sp in line.split()[1:] }
    for sp in pn_dict.keys():

        sp_file = os.path.join(pd_dir, "runtime", sp)
        if not os.path.exists(sp_file):
            continue

        with open (sp_file, 'r') as infile:
            for line in infile:
                key, value = line.split(":", 1)
                pn_dict[sp][key] = oe.utils.squashspaces(value)

    dict_out = dict()
    for pkg in pn_dict.keys():
        dict_out[pkg] = dict()
        read_extvar_list("pkg", pkg, pn_dict[pkg], dict_out[pkg])
        read_extlvar_list("pkg", pkg, pn_dict[pkg], dict_out[pkg])

    tsmeta_write_dict(d, "pkg", dict_out)



def tsmeta_get_packageconfig(d):
    import oe.packagedata

    tgv_type = "packageconfig"

    dest_dict = dict(
        depends = list(),
        rdepends = list(),
        rrecommends = list(),
    )

    pkgconfig = (d.getVar('PACKAGECONFIG') or "").split()
    if not pkgconfig:
        return

    pkgconfigflags = d.getVarFlags("PACKAGECONFIG") or {}
    if pkgconfigflags:

        for flag, flagval in sorted(pkgconfigflags.items()):
            items = flagval.split(",")
            num = len(items)
            if num > 5:
                bb.warning("%s: PACKAGECONFIG[%s] Only enable,disable,depend,rdepend,rrecommend can be specified!"
                    % (d.getVar('PN'), flag))

            if flag in pkgconfig:
                if num >= 3 and items[2]:
                    dest_dict['depends'].append(items[2])
                if num >= 4 and items[3]:
                    dest_dict['rdepends'].append(items[3])
                if num >= 5 and items[4]:
                    dest_dict['rrecommends'].append(items[4])

    tsmeta_write_dict(d, tgv_type, dest_dict)


python do_tsmeta_pkgvars() {
    tsmeta_get_pn(d)
    tsmeta_get_recipe(d)
    tsmeta_get_src(d)
    tsmeta_get_pkg(d)
    tsmeta_get_packageconfig(d)
}


def tsmeta_collect_preferred(d):
    import json
    pref_filter = dict(
        provider = "PREFERRED_PROVIDER_",
        version = "PREFERRED_VERSION_",
        runtime = "VIRTUAL-RUNTIME_",
    )

    d_keys = sorted(d.keys())
    p_dict = {
        p_name: { 
                key.replace(p_type, "") : d.getVar(key)
                    for key in d_keys if key.startswith(p_type) 
                }
                for p_name, p_type in pref_filter.items() 
            }

    # bb.plain("%s" % json.dumps(p_dict, indent = 4, sort_keys = True))
    return p_dict

python tsmeta_get_preferred() {
    tsmeta_write_dictdir(d, "preferred", 
        tsmeta_collect_preferred(d))
}


python tsmeta_get_machine() {
    tempdict = { key.replace("MACHINE_", "").lower(): \
        oe.utils.squashspaces(str(d.getVar(key))) \
        for key in d.keys() if key.startswith("MACHINE_") and \
            not key.startswith("MACHINE_FEATURES") }

    mdict = dict()
    for key in tempdict.keys():
        if key.startswith("features")   or \
            key.startswith("essential") or \
            key.startswith("extra")     or \
            key.endswith("filter")      or \
            key.endswith("codecs")      or \
            key.endswith("firmware"):
            mdict[key] = (tempdict[key] or "").split()
        else:
            mdict[key] = tempdict[key]

    mdict['title'] = d.getVar('MACHINE')
    tsmeta_write_dictname(d, "machine", mdict["title"], mdict)
}

python tsmeta_get_distro() {
    tempdict = { key.replace("DISTRO_", "").lower(): \
        oe.utils.squashspaces(str(d.getVar(key))) \
        for key in d.keys() if key.startswith("DISTRO_") and \
            not key.startswith("DISTRO_FEATURES") }

    ddict = dict()
    for key in tempdict.keys():
        if key.startswith("features")   or \
            key.startswith("essential") or \
            key.startswith("extra")     or \
            key.endswith("filter")      or \
            key.endswith("codecs")      or \
            key.endswith("firmware"):
            ddict[key] = (tempdict[key] or "").split()
        else:
            ddict[key] = tempdict[key]

    ddict['title'] = d.getVar('DISTRO')
    tsmeta_write_dictname(d, "distro", ddict["title"], ddict)
}

python tsmeta_get_image() {

    tempdict = { key.replace("IMAGE_", "").lower(): d.getVar(key) \
        for key in d.keys() if key.startswith("IMAGE_") and \
        not (key.startswith("IMAGE_CMD_") or key.startswith("IMAGE_FEATURES")) }

    extra_keys = [
        'EXTRA_IMAGE_INSTALL',
        'PACKAGE_INSTALL',
        'RDEPENDS',
        'RRECOMMENDS'
    ]
    extra_dict = { key.lower(): (d.getVar(key) or "") for key in extra_keys }

    tempdict.update( { key: oe.utils.squashspaces(value).split() for key, value in extra_dict.items()
            if len(value) and isinstance(value, str) } )

    imgdict = dict()

    for key in tempdict.keys():
        if  key.startswith("features")  or \
            key.startswith("fstypes")   or \
            key.startswith("install")   or \
            key.startswith("linguas")   or \
            key.endswith("files")       or \
            key.endswith("command")     or \
            key.endswith("classes")     or \
            key.endswith("types"):
            imgdict[key] = (tempdict[key] or "").split()
        else:
            imgdict[key] = tempdict[key]

    tsmeta_write_dictname(d, "image", imgdict["basename"], imgdict)
}

python tsmeta_get_features() {
    fdict = dict(
        distro = { key.replace("DISTRO_FEATURES_", "").lower(): \
                    oe.utils.squashspaces(str(d.getVar(key))).split()  \
                    for key in d.keys() if key.startswith("DISTRO_FEATURES_")  },
        machine = { key.replace("MACHINE_FEATURES_", "").lower(): \
                    oe.utils.squashspaces(str(d.getVar(key))).split()  \
                    for key in d.keys() if key.startswith("MACHINE_FEATURES_")  },
        image = { key.replace("IMAGE_FEATURES_", "").lower(): \
                    oe.utils.squashspaces(str(d.getVar(key))).split()  \
                    for key in d.keys() if key.startswith("IMAGE_FEATURES_")  },
        packages = { key.replace("FEATURE_PACKAGES_", "").lower(): \
                    oe.utils.squashspaces(str(d.getVar(key))).split()  \
                    for key in d.keys() if key.startswith("FEATURE_PACKAGES_")  },
    )

    fdict['distro']['base']     = d.getVar('DISTRO_FEATURES').split()
    fdict['machine']['base']    = d.getVar('MACHINE_FEATURES').split()
    fdict['image']['base']      = d.getVar('IMAGE_FEATURES').split()

    tsmeta_write_dictdir(d, "features", fdict)
}



def tsmeta_git_branch_info(d, path):
    import bb.process

    branch_dict = dict(
            branch = "HEAD",
            revision = "HEAD",
            upstream = "detached",
            remote = "none",
        )

    try:
        git_out, _ = bb.process.run("git for-each-ref --python \
                --points-at=HEAD  \
                --format='%(refname:short) %(objectname) %(upstream:remotename) %(upstream:short) %(symref:short) '",
                cwd=path)
    except bb.process.ExecutionError:
        git_out = ""


    for reflog in git_out.split('\n'):
        if not reflog:
            continue
        # bb.plain("One Reflog: %s" % reflog)
        (b_name, b_rev, b_remote, b_upstream, b_symref) = [ x.replace("'", "") for x in reflog.split() ]
        b_info = dict(
            branch = b_name,
            revision = b_rev,
            remote = b_remote,
            upstream = b_upstream,
            )
        # bb.plain("One Branch Info: %s" % b_info )
        if b_symref:
            b_info["upstream"] = b_symref

        if b_upstream:
            branch_dict = b_info
            break
        elif branch_dict["branch"] != "HEAD":
            branch_dict = b_info

    r_name = branch_dict["remote"]
    if r_name and r_name != "none":
        try:
            sub_out, _ = bb.process.run(("git remote get-url %s" % r_name), cwd=path)
        except bb.process.ExecutionError:
            sub_out = ''
        branch_dict["url"] = oe.utils.squashspaces(sub_out)

    return branch_dict


def tsmeta_collect_layers(d):
    import re

    layer_dict = dict()

    bspdir = d.getVar('BSPDIR')
    bblayers = d.getVar('BBLAYERS').split()

    lpats = { key.replace("BBFILE_PATTERN_", ""): d.getVar(key)
        for key in d.keys() if key.startswith("BBFILE_PATTERN_") }

    lcompats = { key.replace("LAYERSERIES_COMPAT_", ""): [ d.getVar(key) ]
        for key in d.keys() if key.startswith("LAYERSERIES_COMPAT_") }


    for lll in bblayers:
        for lname in lpats.keys():
            testpath = os.path.join(lll, "conf", "layer.conf")
            lpattern = lpats[lname]
            if re.match(lpattern, testpath):
                layer_dict[lname] = dict(
                        conf_name   = lname,
                        fs_name     = os.path.basename(lll),
                        compat      = lcompats.get(lname),
                        path        = lll,
                        pattern     = lpattern,
                        bsp_path    = os.path.relpath(lll, bspdir),
                    )
                layer_dict[lname].update(
                    tsmeta_git_branch_info(d, lll))
                break

    return layer_dict

python tsmeta_get_layers() {
    tsmeta_write_dictdir(d, "layers",
        tsmeta_collect_layers(d))
}


python do_tsmeta_build() {
    dict_names = [ 'features', 'image', 'preferred' ]

    for d_name in dict_names:
        bb.build.exec_func("tsmeta_get_" + d_name, d)
}

addtask do_tsmeta_build
do_tsmeta_build[nostamp] = "1"


def tsmeta_pn_list(d):
    import json

    pn = d.getVar('PN')
    machine = d.getVar('MACHINE')
    distro = d.getVar('DISTRO')


    dict_names = [ 'layers', 'image', 'distro', 'features', 'machine' ]
    build_dict = dict(
            image = tsmeta_read_dictname_vars(d, "image", pn,
                [ 'install', 'install_debugfs', 'install_complementary' ] ),
            distro = tsmeta_read_dictname_vars(d, "distro", distro,
                [ 'extra_rdepends', 'extra_rrecommends' ] ),
            machine = tsmeta_read_dictname_vars(d, "machine", machine,
                [ 'extra_rdepends', 'essential_extra_rdepends', 'extra_rrecommends', 'essential_extra_rrecommends' ] ),
            features = tsmeta_read_dictdir(d, "features"),
        )

    pkg_dict_base = tsmeta_read_dictdir(d, "pkg")

    pkg_lookup = dict()
    rproviders = dict()
    aliases = dict()
    virtual = tsmeta_read_dictdir(d, "preferred")

    for (pn, pn_dict) in pkg_dict_base.items():
        for (pkg, pkg_dict) in pn_dict.items():
            pkg_name = pkg_dict.get("pkg")

            pkg_lookup[pkg] = dict(
                    pn = pn,
                    rdepends = [ val.split(" ")[0] for val in pkg_dict.get("rdepends", []) ],
                    rrecommends = [ val.split(" ")[0] for val in pkg_dict.get("rrecommends", []) ],
                    rprovides = [ val.split(" ")[0] for val in pkg_dict.get("rprovides", []) ],
                )

            if pkg_name != pkg and not pkg_name in pkg_lookup.keys():
                # pkg_lookup[pkg_name] = dict( pkg_lookup[pkg] )
                # pkg_lookup[pkg_name]["alias"] = pkg
                aliases[pkg_name] = pkg

            for feature in pkg_lookup[pkg]["rprovides"]:
                if not feature in virtual.keys():
                    rproviders[feature] = pkg

    #    pkgdir = d.getVar('VIGILES_DIR_PACKAGES')
    #    build_out = os.path.join(pkgdir, "%s-build.json" % pn)
    #    global_out = os.path.join(pkgdir, "%s-global.json" % pn)
    #    lookup_out = os.path.join(pkgdir, "%s-lookup.json" % pn)
    #    base_out = os.path.join(pkgdir, "%s-base.json" % pn)
    #
    #    bb.utils.mkdirhier(pkgdir)
    #    with open(build_out, 'w') as f_out:
    #        f_out.write(json.dumps(build_dict, indent = 4, sort_keys = True ))
    #
    #    with open(global_out, 'w') as f_out:
    #        f_out.write(json.dumps(pkg_dict_base, indent = 4, sort_keys = True ))
    #
    #    with open(lookup_out, 'w') as f_out:
    #        f_out.write(json.dumps(pkg_lookup, indent = 4, sort_keys = True ))
    #

    pn_base_list = build_dict["image"].get("install") + \
        build_dict["machine"].get("essential_extra_rdepends") + \
        build_dict["machine"].get("essential_extra_rrecommends") + \
        (d.getVar('PACKAGE_INSTALL') or "").split() + \
        (d.getVar('RDEPENDS') or "").split() + \
        (d.getVar('RRECOMMENDS') or "").split()
    left_to_check = list( pn_base_list )
    pn_checked = []
    pn_out = []

    while len(left_to_check):
        for ppp in sorted(left_to_check):

            new_deps = []
            left_to_check.remove(ppp)

            if ppp in pn_checked:
                bb.debug(2,"Skipping %s" % ppp)
                continue

            pn_name = str()
            if ppp in pkg_lookup.keys():
                pn_name = ppp
                bb.debug(2,"Checking %s (pn found)" % ppp)
            elif ppp in aliases.keys():
                pn_name = aliases.get(ppp)
                bb.debug(2,"Checking %s (alias %s found)" % (ppp, pn_name))
            elif ppp in virtual["provider"].keys():
                pn_name = virtual["provider"].get(ppp)
                bb.debug(2,"Checking %s (provider %s found)" % (ppp, pn_name))
            elif ppp in virtual["runtime"].keys():
                pn_name = virtual["runtime"].get(ppp)
                bb.debug(2,"Checking %s (runtime %s found)" % (ppp, pn_name))
            elif ppp in rproviders.keys():
                pn_name = rproviders.get(ppp)
                bb.debug(2,"Checking %s (rprovider %s found)" % (ppp, pn_name))
            else:
                bb.debug(1, "%s: No pkg entry found" % ppp)
                continue

            p_dict = pkg_lookup.get(pn_name, {})
            # bb.plain("%s rdepends: %s" % (ppp, json.dumps(p_dict, indent = 4, sort_keys = True )))
            new_deps = p_dict.get("rdepends", []) + p_dict.get("rrecommends", [])

            pn_checked.append(ppp)

            pkg_pn = p_dict.get("pn", "None")
            if not pkg_pn in pn_out:
                pn_out.append(pkg_pn)

            left_to_check += [ pkg for pkg in new_deps 
                if not (pkg in pn_checked or pkg in left_to_check) ]

    return sorted(pn_out)


python() {
    pn = d.getVar('PN')
    context = (d.getVar('BB_WORKERCONTEXT') or "")
    if context and bb.data.inherits_class('image', d):
        bb.build.exec_func("do_tsmeta_build", d)
}

addhandler tsmeta_eventhandler
tsmeta_eventhandler[eventmask] = "bb.event.BuildStarted"
python tsmeta_eventhandler() {
    import bb.runqueue

    dict_names = [ 'distro', 'layers', 'machine' ]

    for d_name in dict_names:
        bb.build.exec_func("tsmeta_get_" + d_name, d)
}
