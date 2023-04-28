# frozen_string_literal: true

require "logger"
require "event_manager"

RSpec.describe EventManager do
  subject(:event_manager) { described_class.new(logger) }

  let!(:logger) { Logger.new($stdout) }

  describe "required public API" do
    it { is_expected.to respond_to(:subscribe) }
    it { is_expected.to respond_to(:unsubscribe) }
    it { is_expected.to respond_to(:broadcast) }
  end

  describe "usage" do
    context "with handler" do
      it "can be subscribed, unsubscribed and subscribed again" do
        handler = proc {}
        event_manager.subscribe(&handler)
        event_manager.unsubscribe(&handler)
        event_manager.subscribe(&handler)

        expect(event_manager.handlers).to contain_exactly(handler)
      end
    end
  end

  describe "#handlers" do
    it { expect(event_manager.handlers).to be_an(Array) }
    it { expect(event_manager.handlers).to be_empty }
  end

  describe "#subscribe" do
    let(:amount) { 3 }

    context "when the handlers list is empty" do
      it "adds the handler to the list of handlers" do
        handler = proc {}
        event_manager.subscribe(&handler)

        expect(event_manager.handlers).to contain_exactly(handler)
      end
    end

    context "when handlers list is NOT empty" do
      context "when handler objects differ" do
        it "adds all of the handlers" do
          amount.times { event_manager.subscribe {} }

          expect(event_manager.handlers.count).to eq(amount)
        end
      end

      context "when handler objects are the same" do
        it "adds only one handler" do
          handler = proc {}
          amount.times { event_manager.subscribe(&handler) }

          expect(event_manager.handlers).to contain_exactly(handler)
        end
      end
    end
  end

  describe "#unsubscribe" do
    context "when handler already exists" do
      it "removes the handler from the list of handlers" do
        handler_1 = handler_2 = proc {}
        event_manager.subscribe(&handler_1)
        event_manager.unsubscribe(&handler_2)

        expect(handler_1).to equal(handler_2)
        expect(event_manager.handlers).to be_empty
      end
    end

    context "when the handlers list is empty" do
      it "does not raise an error" do
        expect { event_manager.unsubscribe {} }.not_to raise_error
      end

      it "does not change the handlers list" do
        expect { event_manager.unsubscribe {} }.not_to change(event_manager, :handlers)
      end
    end

    context "when handler does NOT exist" do
      it "does NOT remove the handler from the list of handlers" do
        handler_1, handler_2 = proc {}, proc {}
        event_manager.subscribe(&handler_1)
        event_manager.unsubscribe(&handler_2)

        expect(handler_1).not_to equal(handler_2)
        expect(event_manager.handlers).to contain_exactly(handler_1)
      end
    end
  end

  describe "#broadcast" do
    let(:amount) { 3 }

    it "calls all the handlers with the given arguments" do
      amount.times { event_manager.subscribe { |*args| } }

      expect(event_manager.handlers).to all(receive(:call).with(:one, :two, :three))
      event_manager.broadcast(:one, :two, :three)
    end

    context "when broadcast provides MORE arguments than the handlers accept" do
      it "does not raise errors" do
        amount.times { event_manager.subscribe {} }

        expect { event_manager.broadcast(:one, :two, :three) }.not_to raise_error
      end

      it "drops extra arguments" do
        event_manager.subscribe { _1 }

        expect(event_manager.broadcast(:one, :two, :three)).to eq([:one])
      end
    end

    context "when broadcast provides LESS arguments than the handlers accept" do
      it "does not raise errors" do
        amount.times { event_manager.subscribe { [_1, _2, _3] } }

        expect { event_manager.broadcast(:one) }.not_to raise_error
      end

      it "missing arguments are set to nil" do
        event_manager.subscribe { [_1, _2, _3] }

        expect(event_manager.broadcast(:one)).to eq([[:one, nil, nil]])
      end
    end

    context "when handler throws an error" do
      let(:problematic_handler) { proc { "boom" + :one } }

      before { [proc {}, problematic_handler, proc {}].each { event_manager.subscribe(&_1) } }

      it "does not raise error" do
        allow(logger).to receive(:error) # prevent the pollution of RSpec ouput

        expect { problematic_handler.call }.to raise_error(TypeError)
        expect { event_manager.broadcast }.not_to raise_error
      end

      it "calls all of the handlers" do
        expect { problematic_handler.call }.to raise_error(TypeError)
        expect(event_manager.handlers).to all(receive(:call).with(no_args))

        event_manager.broadcast
      end

      it "logs the error" do
        expect { problematic_handler.call }.to raise_error(TypeError)
        expect(logger).to receive(:error).with(kind_of(TypeError))

        event_manager.broadcast
      end
    end
  end
end
