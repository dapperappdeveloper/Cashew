import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/categoryEntry.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/pageFramework.dart';
import 'package:budget/widgets/popupFramework.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/selectCategory.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:budget/colors.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:convert';
import 'package:flutter/services.dart' hide TextInput;

class AddWalletPage extends StatefulWidget {
  AddWalletPage({
    Key? key,
    required this.title,
    this.wallet,
  }) : super(key: key);
  final String title;

  //When a wallet is passed in, we are editing that wallet
  final TransactionWallet? wallet;

  @override
  _AddWalletPageState createState() => _AddWalletPageState();
}

class _AddWalletPageState extends State<AddWalletPage> {
  bool? canAddWallet;

  String? selectedTitle;
  Color? selectedColor;
  String? selectedIconName;
  List<dynamic> currencies = [];

  late FocusNode _periodLengthFocusNode;

  String? textAddWallet = "Add Wallet";

  Future<void> selectColor(BuildContext context) async {
    openBottomSheet(
      context,
      PopupFramework(
        title: "Select Color",
        child: SelectColor(
          selectedColor: selectedColor,
          setSelectedColor: setSelectedColor,
        ),
      ),
    );
  }

  Future<void> selectTitle() async {
    openBottomSheet(
      context,
      PopupFramework(
        title: "Enter Name",
        child: SelectText(
          setSelectedText: setSelectedTitle,
          labelText: "Name",
          selectedText: selectedTitle,
        ),
      ),
      snap: false,
    );
  }

  void setSelectedTitle(String title) {
    setState(() {
      selectedTitle = title;
    });
    determineBottomButton();
    return;
  }

  void setSelectedColor(Color? color) {
    selectedColor = color;
    determineBottomButton();
    return;
  }

  void setSelectedIconName(String iconName) {
    setState(() {
      selectedIconName = iconName;
    });
    return;
  }

  Future addWallet() async {
    print("Added wallet");
    await database.createOrUpdateWallet(await createTransactionWallet());
    Navigator.pop(context);
  }

  Future<TransactionWallet> createTransactionWallet() async {
    int numberOfWallets = (await database.getTotalCountOfWallets())[0] ?? 0;
    return TransactionWallet(
      walletPk: widget.wallet != null
          ? widget.wallet!.walletPk
          : DateTime.now().millisecondsSinceEpoch,
      name: selectedTitle ?? "",
      colour: toHexString(selectedColor),
      dateCreated:
          widget.wallet != null ? widget.wallet!.dateCreated : DateTime.now(),
      order: widget.wallet != null ? widget.wallet!.order : numberOfWallets,
      iconName: selectedIconName,
    );
  }

  @override
  void initState() {
    super.initState();
    _periodLengthFocusNode = FocusNode();

    if (widget.wallet != null) {
      //We are editing a wallet
      textAddWallet = "Edit Wallet";
      //Fill in the information from the passed in wallet
      //Outside of future.delayed because of textinput when in web mode initial value
      selectedTitle = widget.wallet!.name;
      selectedColor = widget.wallet!.colour == null
          ? null
          : HexColor(widget.wallet!.colour);
      Future.delayed(Duration.zero, () async {
        String response =
            await rootBundle.loadString('assets/static/currencies.json');
        setState(() {
          //Set to false because we can't save until we made some changes
          canAddWallet = false;
          currencies = jsonDecode(response);
        });
      });
    } else {}
  }

  @override
  void dispose() {
    _periodLengthFocusNode.dispose();
    super.dispose();
  }

  determineBottomButton() {
    if (selectedTitle != null) {
      if (canAddWallet != true)
        this.setState(() {
          canAddWallet = true;
        });
    } else {
      if (canAddWallet != false)
        this.setState(() {
          canAddWallet = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.wallet != null) {
          discardChangesPopup(
            context,
            previousObject: widget.wallet,
            currentObject: await createTransactionWallet(),
          );
        } else {
          discardChangesPopup(context);
        }
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            //Minimize keyboard when tap non interactive widget
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: Stack(
            children: [
              PageFramework(
                title: widget.title,
                navbar: false,
                onBackButton: () async {
                  if (widget.wallet != null) {
                    discardChangesPopup(
                      context,
                      previousObject: widget.wallet,
                      currentObject: await createTransactionWallet(),
                    );
                  } else {
                    discardChangesPopup(context);
                  }
                },
                onDragDownToDissmiss: () async {
                  if (widget.wallet != null) {
                    discardChangesPopup(
                      context,
                      previousObject: widget.wallet,
                      currentObject: await createTransactionWallet(),
                    );
                  } else {
                    discardChangesPopup(context);
                  }
                },
                listWidgets: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: kIsWeb
                        ? TextInput(
                            labelText: "Name",
                            bubbly: false,
                            initialValue: selectedTitle,
                            onChanged: (text) {
                              setSelectedTitle(text);
                            },
                            padding: EdgeInsets.only(left: 7, right: 7),
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            topContentPadding: 20,
                          )
                        : TappableTextEntry(
                            title: selectedTitle,
                            placeholder: "Name",
                            onTap: () {
                              selectTitle();
                            },
                            autoSizeText: true,
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                  ),
                  SizedBox(height: 14),
                  Container(
                    height: 65,
                    child: SelectColor(
                      horizontalList: true,
                      selectedColor: selectedColor,
                      setSelectedColor: setSelectedColor,
                    ),
                  ),
                  SizedBox(height: 25),
                  Container(
                    height: 300,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 18.0, right: 18, bottom: 5),
                          child: Tappable(
                            color:
                                Theme.of(context).colorScheme.lightDarkAccent,
                            borderRadius: 10,
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  IntrinsicWidth(
                                    child: Row(
                                      children: [
                                        currencies[index]?["Flag"] != null
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Image.network(
                                                  currencies[index]?["Flag"],
                                                  height: 20,
                                                ),
                                              )
                                            : SizedBox.shrink(),
                                        TextFont(
                                            text: currencies[index]
                                                    ?["CountryName"] ??
                                                currencies[index]?["Currency"]),
                                      ],
                                    ),
                                  ),
                                  IntrinsicWidth(
                                    child: Row(
                                      children: [
                                        TextFont(
                                            text: currencies[index]["Code"]),
                                        SizedBox(width: 15),
                                        TextFont(
                                            text: currencies[index]["Symbol"]),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: canAddWallet ?? false
                    ? Button(
                        label: widget.wallet == null
                            ? "Add Wallet"
                            : "Save Changes",
                        width: MediaQuery.of(context).size.width,
                        height: 50,
                        onTap: () {
                          addWallet();
                        },
                        hasBottomExtraSafeArea: true,
                      )
                    : Button(
                        label: widget.wallet == null
                            ? "Add Wallet"
                            : "Save Changes",
                        width: MediaQuery.of(context).size.width,
                        height: 50,
                        onTap: () {},
                        color: Colors.grey,
                        hasBottomExtraSafeArea: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
