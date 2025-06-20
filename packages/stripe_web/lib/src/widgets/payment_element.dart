import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stripe_js/stripe_api.dart' as js;
import 'package:stripe_js/stripe_js.dart' as js;
import 'package:web/web.dart' as web;

import '../../flutter_stripe_web.dart';

// TODO: should not use src of other package
export 'package:stripe_js/src/api/elements/payment_element_options.dart';
export 'package:stripe_js/stripe_api.dart'
    show
        PaymentElementLayout,
        ElementAppearance,
        ElementTheme,
        ElementAppearanceLabels;

typedef PaymentElementTheme = js.ElementTheme;

class PaymentElement extends StatefulWidget {
  final String clientSecret;
  final String? customerSessionClientSecret;
  final double? width;
  final double? height;
  final CardStyle? style;
  final CardPlaceholder? placeholder;
  final bool enablePostalCode;
  final bool autofocus;
  final FocusNode? focusNode;
  final CardFocusCallback? onFocus;
  final CardChangedCallback onCardChanged;
  final PaymentElementLayout layout;
  final js.ElementAppearance? appearance;
  final js.PaymentElementDefaultValues? defaultValues;
  final js.PaymentElementBusiness? business;
  final dynamic paymentMethodOrder;
  final js.PaymentElementFields? fields;
  final bool? readOnly;
  final js.PaymentElementOptionsTerms? terms;
  final js.PaymentElementWalletOptions? wallets;
  final js.PaymentElementApplePayOptions? applePay;

  const PaymentElement({
    super.key,
    required this.clientSecret,
    this.customerSessionClientSecret,
    this.width,
    this.height,
    this.style,
    this.placeholder,
    this.enablePostalCode = false,
    this.autofocus = false,
    this.focusNode,
    this.onFocus,
    required this.onCardChanged,
    this.layout = PaymentElementLayout.accordion,
    this.appearance,
    this.defaultValues,
    this.business,
    this.paymentMethodOrder,
    this.fields,
    this.readOnly,
    this.terms,
    this.wallets,
    this.applePay,
  });

  @override
  State<PaymentElement> createState() => PaymentElementState();
}

class PaymentElementState extends State<PaymentElement> {
  web.HTMLDivElement _divElement = web.HTMLDivElement();
  // 2 is the first size generated by the iframe, O will not work.
  double height = 2.0;

  late web.MutationObserver? mutationObserver = web.MutationObserver(
    ((JSArray<web.MutationRecord> entries, web.MutationObserver observer) {
      if (web.document.getElementById('payment-element') != null) {
        mutationObserver?.disconnect();
        element = elements!.createPayment(elementOptions())
          ..mount('#payment-element'.toJS)
          ..onBlur(requestBlur)
          ..onFocus(requestFocus)
          ..onChange(onCardChanged);
        mutationObserver = web.MutationObserver((JSArray<web.MutationRecord> entries, web.MutationObserver observer) {
          final stripeElements = web.document.getElementsByClassName('__PrivateStripeElement');
          if (stripeElements.length != 0) {
            mutationObserver?.disconnect();
            final element = stripeElements.item(0) as web.HTMLElement;
            resizeObserver.observe(element);
          }
        }.toJS);
        mutationObserver!.observe(
          web.document,
          web.MutationObserverInit(childList: true, subtree: true),
        );
      }
    }.toJS),
  );

  late final resizeObserver = web.ResizeObserver(
    ((JSArray<web.ResizeObserverEntry> entries, web.ResizeObserver observer) {
      if (widget.height == null) {
        for (final entry in entries.toDart) {
          final cr = entry.contentRect;
          setState(() {
            height = cr.height.toDouble();
            _divElement.style.height = '${height}px';
          });
        }
      }
    }).toJS,
  );

  @override
  void initState() {
    height = widget.height ?? height;

    _divElement = web.HTMLDivElement()
      ..id = 'payment-element'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '$height';

    elements = WebStripe.js.elements(createOptions());
    mutationObserver!.observe(
      web.document,
      web.MutationObserverInit(childList: true, subtree: true),
    );
    ui.platformViewRegistry.registerViewFactory(
      'stripe_payment_element',
      (int viewId) => _divElement,
    );

    super.initState();
  }

  js.PaymentElement? get element => WebStripe.element as js.PaymentElement?;
  set element(js.StripeElement? value) => WebStripe.element = value;

  js.StripeElements? get elements => WebStripe.elements;
  set elements(js.StripeElements? value) => WebStripe.elements = value;

  void requestBlur(response) {
    _effectiveNode.unfocus();
  }

  void requestFocus(response) {
    if (widget.onFocus != null) {
      widget.onFocus!(null);
    }

    _effectiveNode.requestFocus();
  }

  void onCardChanged(js.PaymentElementChangeEvent response) {
    final details = CardFieldInputDetails(
      complete: response.complete,
    );
    widget.onCardChanged(details);

    return;
  }

  final FocusNode _focusNode = FocusNode(debugLabel: 'CardField');
  FocusNode get _effectiveNode => widget.focusNode ?? _focusNode;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _effectiveNode,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: height,
        ),
        child: const HtmlElementView(viewType: 'stripe_payment_element'),
      ),
    );
  }

  js.JsElementsCreateOptions createOptions() {
    final appearance = widget.appearance ?? js.ElementAppearance();
    return js.JsElementsCreateOptions(
      clientSecret: widget.clientSecret,
      customerSessionClientSecret: widget.customerSessionClientSecret,
      appearance: appearance.toJson().jsify() as js.JsElementAppearance,
    );
  }

  js.PaymentElementOptions elementOptions() {
    return js.PaymentElementOptions(
      layout: widget.layout,
      defaultValues: widget.defaultValues,
      business: widget.business,
      paymentMethodOrder: widget.paymentMethodOrder,
      fields: widget.fields,
      readOnly: widget.readOnly,
      terms: widget.terms,
      wallets: widget.wallets,
      applePay: widget.applePay,
    );
  }

  @override
  void didUpdateWidget(covariant PaymentElement oldWidget) {
    if (widget.enablePostalCode != oldWidget.enablePostalCode ||
        widget.placeholder != oldWidget.placeholder ||
        widget.style != oldWidget.style) {}
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    mutationObserver?.disconnect();
    resizeObserver.disconnect();
    element?.unmount();

    super.dispose();
  }
}
