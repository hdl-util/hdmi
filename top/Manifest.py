files = [
    "top.sv",
]

modules = {
    "local": [
        "../src"
    ],
    "git": [
        "https://github.com/hdl-util/pll.git::master"
    ]
}

fetchto = "../ip_cores"
