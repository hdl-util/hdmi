files = [
    "top.sv",
]

modules = {
    "local": [
        "../hdmi"
    ],
    "git": [
        "git@github.com:hdl-util/pll.git::master"
    ]
}

fetchto = "../ip_cores"
